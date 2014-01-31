#require 'rack'

class App

  def call(environ)
      [200, {'Content-Type' => 'text/html'}, ['<h1>','Hello, Ruby Rack!', '</h1>']]
  end
        
end
        
#run App.new, :Port => 9999
run App.new
