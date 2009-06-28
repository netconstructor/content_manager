module Content
  module Manager
    def show
      render404 and return if current_content_item.nil? or current_content_item.template.nil? or current_content_item.template.sublayout.nil?
      respond_to do |format|
        format.html { prerender_containers and render :template => "sublayouts/#{current_content_item.template.sublayout}", :layout => false }
        format.xml  { render :xml => current_content_item }
      end
    end

  private
    def prerender_containers
      sublayout = Content::Sublayout.find_by_path(current_content_item.template.sublayout)
      unless sublayout.nil?
        begin
          sublayout.containers.each {|name| content_for name, render_container(name) }
        rescue RuntimeError => err
          render500(err) and return false
        end
        true
      else
        false
      end
    end

    def content_for(name, content)
      ivar = "@content_for_#{name}"
      instance_variable_set(ivar, "#{instance_variable_get(ivar)}#{content}")
    end

    def choose_layout
      :application unless params[:action] == "show"
    end

    def render500(err)
      respond_to do |format| 
        format.html { render :text => err, :layout => false, :status => 500 } 
        format.all  { render :nothing => true, :status => 500 } 
      end
      true
    end

  protected
    #
    # Renders the given component
    #
    # url_options the options that would be passed to url_for
    #
    def render_component(url_options)
      url = url_for(url_options)
      querystring = URI.parse(url).query

      env = {
        "rack.version" => [0, 1],
        "rack.input" => StringIO.new(""),
        "rack.errors" => $stderr,
        "rack.url_scheme" => "http",
        "rack.run_once" => false,
        "rack.multithread" => false,
        "rack.multiprocess" => false,
        "QUERY_STRING" => querystring,
        "REQUEST_METHOD" => "GET",
        "PATH_INFO" => url,
        "REQUEST_PATH" => url,
        "REQUEST_URI" => url
      }

      %w(SERVER_SOFTWARE HTTP_USER_AGENT HTTP_ACCEPT_ENCODING HTTP_ACCEPT_CHARSET
        HTTP_ACCEPT_LANGUAGE HTTP_KEEP_ALIVE HTTP_COOKIE HTTP_VERSION SERVER_PROTOCOL HTTP_HOST
        SERVER_NAME SERVER_PORT REMOTE_ADDR SCRIPT_NAME).each { |key| env[key] = request.env[key] }

      resp = ActionController::Routing::Routes.call(env)
      raise resp[2].body unless resp[0] == 200
      resp[2].body
    end

    #
    # Renders a container
    #
    # name the name of the container to render
    #
    def render_container(name)
      current_content_item.template.components_hash[name].collect {|component|
        render_component(:controller => "components/#{component.keys.first.to_s.pluralize}", :action => "show", :id => component.values.first)
      } unless current_content_item.nil? or current_content_item.template.nil? or current_content_item.template.components_hash.nil? or current_content_item.template.components_hash[name].nil?
    end

    def render404
      respond_to do |format| 
        format.html { render :template => "errors/error_404", :status => 404 } 
        format.all  { render :nothing => true, :status => 404 } 
      end
      true
    end

    def current_content_item
      @content_item ||= begin
        url = params["content_item_url"]
        unless url.nil?
          if url.is_a? Array
            url = "/#{url.join('/')}"
          else
            url = url.to_s
          end
          if url.match(/^(.+)\.([a-z]+)$/i)
            params[:format] = $2
            url = $1
          end
          params["content_item_url"] = url
          Content::Item.find_by_url(url)
        end
      end
    end
  end
end
