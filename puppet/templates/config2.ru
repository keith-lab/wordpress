require 'rack'

class Application
  def call(env)
    return [200, {'Content-Type' => 'text/plain'}, ['Hello world I am unicorn instance 2']]
  end
end

run Application.new
