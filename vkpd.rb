#!/usr/bin/env ruby
require "net/http"
require "net/https"
require "cgi"
require "yaml"
require "json"

method = "audio.search"
params = {}
action_before = 'mpc clear'
action_after  = 'mpc play'

config = YAML.load File.read("#{ENV['HOME']}/.config/vkpd.yaml")
params["access_token"]=config["access_token"]

while ARGV.size > 0
  current = ARGV.shift
  case current
  when '-h','--help'
    puts man=<<EOF
Fork me, write manual and make pull-request
EOF
    exit 0
  when '-c', '--count', /^--count=\d+$/
    value = current.include?("=") ? current.match(/=(.*)/)[1] : ARGV.shift
    params["count"]  = value
  when '-o', '--offset', /^--offset=\d+$/
    value = current.include?("=") ? current.match(/=(.*)/)[1] : ARGV.shift
    params["offset"] = value
  when '-s', '--sort', /^--sort=\d+$/
    value = current.include?("=") ? current.match(/=(.*)/)[1] : ARGV.shift
    params["sort"] = value
  when 'user'
    method = 'audio.get'
    if !ARGV.empty? and ARGV.first.match(/^\d+$/)
      params['uid'] = ARGV.shift
    else
      params['uid'] = config["user_id"]
    end
  when 'group'
    method = 'audio.get'
    params['gid'] = ARGV.shift
  when 'add'
    action_before = ''
    action_after = ''
  when '-f','--fix'
    params["auto_complete"] = '1'
  when 'play'
    # do nothing
  else
    params["q"]=ARGV.unshift(current).join(" ")
    ARGV.clear
  end
end

def hash_to_params(hash)
  hash.map{|k,v| "#{k}=#{CGI.escape(v.to_s)}"}.join("&")
end

unless File.exist? "#{ENV['HOME']}/.config/vkpd.yaml"
  puts 'Please authenticate. Start vkpd-auth.rb and point your browser to http://localhost.local:4567/'
  exit 1
end

connection=Net::HTTP.new("api.vkontakte.ru",443)
connection.use_ssl=true
data=connection.get("/method/#{method}?#{hash_to_params(params)}").body
response = JSON.parse(data)["response"]
if method.match /search/
  response.shift
end
system action_before
response.each do |song|
  system "mpc add #{song["url"]}"
end
system action_after
