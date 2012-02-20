#!/usr/bin/env ruby
require "sinatra/base"
require "net/http"
require "net/https"
require "yaml"

APP_ID='2803517'
class VKPD < Sinatra::Base
  def auth_url(app_id,settings,redirect_uri,display)
    "http://oauth.vkontakte.ru/authorize?client_id=#{app_id}&scope=#{settings}&redirect_uri=#{redirect_uri}&display=#{display}&response_type=token"
  end

  get '/' do
    redirect auth_url(APP_ID,"audio,offline","#{request.host}:#{request.port}/return","page")
  end

  get '/return' do
    '<html><head><script type="text/javascript" src="https://www.google.com/jsapi"></script><script>
google.load("jquery", "1.7.1");
  var hash = location.hash.replace("#","/auth_data?");
  location.href = hash;
</script></head><body>'+ params.to_s + '</body></html>'
  end

  get '/auth_data' do
    File.open("#{ENV['HOME']}/.config/vkpd.yaml", "w") do |f|
      f.write(params.merge({"app_id" => APP_ID}).to_yaml)
    end
    Thread.new do
      sleep 0.5
      puts "Authorized. Terminating now."
      Kernel.exec("true")
    end
    "authorized. now close me and go back to your term"
  end
end
VKPD.run!
