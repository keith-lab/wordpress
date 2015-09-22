require 'rack'

class Application
  def call(env)
    return [200, {'Content-Type' => 'text/plain'}, ['Hello world']]
  end
end

run Application.new
