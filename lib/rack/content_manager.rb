module Rack
  class ContentManager
    def initialize(app)
      @app = app
    end

    def call(env)
      item = ContentItem.find_first_by_url(env["REQUEST_PATH"])
      if item.nil?
        @app.call(env)
      else
        response = Rack::Response.new
        response.write "Hi there"
        response.finish
      end
    end
  end
end
