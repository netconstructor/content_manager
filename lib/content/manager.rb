module Content
  module Manager
    def self.load_content_item(params)
      url = params[:content_item_url]
      unless url.nil?
        if url.is_a? Array
          url = "/#{url.join('/')}"
        end
        if url.match(/^(.+)\.([a-z]+)$/i)
          params[:format] = $2
          url = $1
        end
        params[:content_item_url] = url
        if Thread.current[:current_item_url] != url or !Thread.current[:current_item_loaded]
          Thread.current[:current_item_url] = url
          Thread.current[:current_item_loaded] = true
          if params[:version].blank?
            Thread.current[:current_item] = Content::Item.find_by_url_and_status(url, :published)
          else
            Thread.current[:current_item] = Content::Item.find_by_url_and_version(url, params[:version])
          end
        end
        Thread.current[:current_item]
      end
    end

    def self.unload_content_item
      Thread.current[:current_item] = nil
      Thread.current[:current_item_loaded] = false
    end

    def show
      redirect_to(current_content_item.see, :status => 301) and return unless current_content_item.nil? or current_content_item.see.nil?
      render_404 and return if current_content_item.nil? or current_content_item.template.nil? or current_content_item.template.sublayout.nil?
      respond_to do |format|
        format.html { prerender_containers and render :template => "sublayouts/#{current_content_item.template.sublayout}", :layout => current_content_item.template.layout }
        format.json { render :json => current_content_json }
        format.xml  { render :xml => current_content_item }
      end
    end

  protected

    def current_content_json
      item = {}
      if current_content_item
        sublayout = Content::Sublayout.find_by_path(current_content_item.template.sublayout)
        item[:id] = current_content_item.id
        item[:url] = current_content_item.url
        item[:template] = {
          :id => current_content_item.template.id,
          :url => current_content_item.template.url,
          :name => current_content_item.template.heading,
          :sublayout => sublayout.name,
          :containers => sublayout.containers
        }
        item[:components] = {}
        sublayout.containers.each do |container|
          item[:components][container] = current_content_item.template.send(container)
        end
      end
      {:success => true, :item => item}.to_json
    end

    def head_profile
      ' profile="http://dublincore.org/documents/2008/08/04/dc-html/"'
    end

    def get_dublin_core(item)
      dc = []
      unless item.nil?
        dc << {:tag => :meta, :name => "DC.title", :content => item.heading} unless item.heading.blank?
        dc << {:tag => :meta, :name => "DC.subject", :content => item.subject} unless item.subject.blank?
        dc << {:tag => :meta, :name => "DC.description", :content => item.summary} unless item.summary.blank?
        dc << {:tag => :meta, :name => "DC.contributor", :content => item.contributor} unless item.contributor.blank?
        dc << {:tag => :meta, :name => "DC.creator", :content => item.author} unless item.creator.blank?
        dc << {:tag => :meta, :name => "DC.publisher", :content => item.publisher} unless item.publisher.blank?
        dc << {:tag => :meta, :name => "DC.source", :content => item.source_url} unless item.source_url.blank?
        dc << {:tag => :meta, :name => "DC.date.issued", :content => item.created_at.iso8601, :scheme => "ISO8601"} unless item.created_at.nil?
        dc << {:tag => :meta, :name => "DC.date.modified", :content => item.updated_at.iso8601, :scheme => "ISO8601"} unless item.updated_at.nil?
        dc << {:tag => :meta, :name => "DC.identifier", :content => request.protocol + request.host_with_port + item.url} unless item.url.blank?
        dc.insert(0, {:tag => :link, :rel  => "schema.DC", :href => "http://purl.org/dc/elements/1.1/"}) if dc.length > 0
      end
      dc
    end

    def prerender_containers
      begin
        @sublayout = Content::Sublayout.find_by_path(current_content_item.template.sublayout)
        if @sublayout.nil?
          raise "Could not load sublayout #{current_content_item.template.sublayout}"
        else
          @sublayout.containers.each {|name| content_for name, render_container(name) }
        end
      rescue RuntimeError => err
        render_500(err) and return false
      end
      true
    end

    def content_for(name, content)
      name = "layout" if name.to_s == "contents"
      ivar = "@content_for_#{name}"
      instance_variable_set(ivar, "#{instance_variable_get(ivar)}#{content}")
    end

    #
    # Renders the given component
    #
    # url_options - the options that would be passed to url_for
    # general_options - options for how to render
    def render_component(url_options, general_options)
      filtered_params = ["action", "controller", "content_item_url"]      
      params.each_pair do |k, v|
        if k.match("(.+)_#{url_options[:id]}_(.+)")
          url_options[$2] = v
        elsif k.match("(.+[a-zA-Z]+)")
          url_options["_page_#{$1}"] = v unless filtered_params.include?($1) or general_options[:no_page_params]
        end
      end
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

      %w(rack.session rack.session.options rack.session.record rack.request.cookie_hash rack.request.cookie_string
        SERVER_SOFTWARE HTTP_USER_AGENT HTTP_ACCEPT_ENCODING HTTP_ACCEPT_CHARSET
        HTTP_ACCEPT_LANGUAGE HTTP_KEEP_ALIVE HTTP_COOKIE HTTP_VERSION SERVER_PROTOCOL HTTP_HOST
        SERVER_NAME SERVER_PORT REMOTE_ADDR SCRIPT_NAME).each { |key| env[key] = request.env[key] }

      resp = ActionController::Routing::Routes.call(env)
      if resp[0] == 200
        after_render_component(resp)[2].body
      else
        raise_component_error(resp[2].body)
      end
    end

    def raise_component_error(err)
      raise err if RAILS_ENV == "development"
      err
    end

    def after_render_component(resp)
      resp
    end

    #
    # Renders a container
    #
    # name the name of the container to render
    #
    def render_container(name)
      get_container(name).collect {|component|
        component_path = "/components/#{component.keys.first.to_s.pluralize}"
        config = "#{component_path}_controller".classify.constantize.component_config?
        url_options = {:controller => component_path, :action => "show", :id => component.values.first}
        if !config.has_key?(:require_content_item) or config[:require_content_item]
          url_options[:content_item_url] = current_content_item.url
        end
        general_options = {}
        unless config[:page_params]
          general_options[:no_page_params] = true
        end
        general_options[:esi] = (!config.has_key?(:esi) or config[:esi])
        render_component(url_options, general_options)
      }
    end

    def get_container(name)
      unless current_content_item.nil? or current_content_item.template.nil? or current_content_item.template[name].nil?
        current_content_item.template.get_container(name)
      else
        []
      end
    end

    def render_404
      respond_to do |format| 
        format.html { render :template => "errors/error_404", :status => 404 } 
        format.all  { render :nothing => true, :status => 404 } 
      end
      true
    end

    def render_500(err)
      respond_to do |format| 
        format.html { render :text => err, :layout => false, :status => 500 } 
        format.all  { render :nothing => true, :status => 500 } 
      end
      true
    end
  end
end
