module Rack
  class ContentManager
    def initialize(app)
      @app = app
    end

    def call(env)
      item = ContentItem.find_first_by_url(env["REQUEST_PATH"])
      unless item.nil?
        response = Rack::Response.new
        response.write "Hi there"
        response.finish
      else
        @app.call(env)
      end
    end
  end
end
