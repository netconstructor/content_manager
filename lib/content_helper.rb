module ContentHelper
  def render_components(name)
    querystring = "" # TODO

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
      "PATH_INFO" => name,
      "REQUEST_PATH" => name,
      "REQUEST_URI" => name
    }
    
    %w(SERVER_SOFTWARE HTTP_USER_AGENT HTTP_ACCEPT_ENCODING HTTP_ACCEPT_CHARSET
      HTTP_ACCEPT_LANGUAGE HTTP_KEEP_ALIVE HTTP_COOKIE HTTP_VERSION SERVER_PROTOCOL HTTP_HOST
      SERVER_NAME SERVER_PORT REMOTE_ADDR SCRIPT_NAME).each { |key| env[key] = request.env[key] }

    resp = ActionController::Dispatcher.new.call(env)
    raise "Error executing component '#{name}' - #{resp[0]}" unless resp[0] == 200
    resp[2].body
  end
end
