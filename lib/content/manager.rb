module Content
  module Manager
    def self.load_content_item(params)
      url = params["content_item_url"]
      unless url.nil?
        if url.is_a? Array
          url = "/#{url.join('/')}"
        end
        if url.match(/^(.+)\.([a-z]+)$/i)
          params[:format] = $2
          url = $1
        end
        params["content_item_url"] = url
        unless Thread.current[:current_item_url] == url 
          Thread.current[:current_item_url] = url
          Thread.current[:current_item] = Content::Item.find_by_url(url)
        else
          Thread.current[:current_item] ||= Content::Item.find_by_url(url)
        end
      end
    end

    def self.unload_content_item
      Thread.current[:current_item] = nil
    end

    def show
      render404 and return if current_content_item.nil? or current_content_item.template.nil? or current_content_item.template.sublayout.nil?
      respond_to do |format|
        format.html { prerender_containers and render :template => "sublayouts/#{current_content_item.template.sublayout}", :layout => current_content_item.template.layout }
        format.xml  { render :xml => current_content_item }
      end
    end

  protected
    # <head profile="<%= get_dublin_core_profile %>">
    def get_dublin_core_profile
      "http://dublincore.org/documents/2008/08/04/dc-html/"
    end

    def get_dublin_core(item)
      dc = []
      unless item.nil?
        dc << {:type => :meta, :name => "DC.title", :content => item.heading} unless item.heading.nil?
        dc << {:type => :meta, :name => "DC.subject", :content => item.subject} unless item.subject.nil?
        dc << {:type => :meta, :name => "DC.description", :content => item.summary} unless item.summary.nil?
        dc << {:type => :meta, :name => "DC.contributor", :content => item.contributor} unless item.contributor.nil?
        dc << {:type => :meta, :name => "DC.creator", :content => item.creator} unless item.creator.nil?
        dc << {:type => :meta, :name => "DC.publisher", :content => item.publisher} unless item.publisher.nil?
        dc << {:type => :meta, :name => "DC.source", :content => item.source} unless item.source.nil?
        dc << {:type => :meta, :name => "DC.date.issued", :content => item.created_at} unless item.created_at.nil?
        dc << {:type => :meta, :name => "DC.date.modified", :content => item.updated_at} unless item.updated_at.nil?
        dc << {:type => :meta, :name => "DC.identifier", :content => item.url} unless item.url.nil?
        dc.insert(0, {:type => :link, :rel  => "schema.DC", :href => "http://purl.org/dc/elements/1.1/"}) if dc.length > 0
      end
      dc
    end

    include ActionView::Helpers::TagHelper

    def format_dublin_core(dc)
      dc.collect do |dc_item|
        if dc_item[:type] == :meta
          tag(:meta, :name => dc_item[:name], :content => dc_item[:content])
        elsif dc_item[:type] == :link
          tag(:link, :rel => dc_item[:rel], :href => dc_item[:href])
        end
      end.join("\r\n")
    end
    
    def prerender_containers
      begin
        @sublayout = Content::Sublayout.find_by_path(current_content_item.template.sublayout)
        @sublayout.containers.each {|name| content_for name, render_container(name) }
      rescue RuntimeError => err
        render500(err) and return false
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
      unless current_content_item.nil? or current_content_item.template.nil? or current_content_item.template[name].nil?
        current_content_item.template.get_container(name).collect {|component|
          render_component(:controller => "components/#{component.keys.first.to_s.pluralize}", :action => "show", :id => component.values.first, :content_item_url => current_content_item.url)
        }
      end
    end

    def render404
      respond_to do |format| 
        format.html { render :template => "errors/error_404", :status => 404 } 
        format.all  { render :nothing => true, :status => 404 } 
      end
      true
    end

    def render500(err)
      respond_to do |format| 
        format.html { render :text => err, :layout => false, :status => 500 } 
        format.all  { render :nothing => true, :status => 500 } 
      end
      true
    end
  end
end
