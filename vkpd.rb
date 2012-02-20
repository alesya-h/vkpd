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

while ARGV.size > 0
  current = ARGV.shift
  case current
  when '-h','--help'
    puts man=<<EOF
manual here
EOF
    exit 0
  when '-c', '--count', /--count=\d+/
    value = current.include?("=") ? current.match(/=(.*)/)[1] : ARGV.shift
    params["count"]  = value
  when '-o', '--offset', /--offset=\d+/
    value = current.include?("=") ? current.match(/=(.*)/)[1] : ARGV.shift
    params["offset"] = value
  when '-s', '--sort', /--sort=\d+/
    value = current.include?("=") ? current.match(/=(.*)/)[1] : ARGV.shift
    params["sort"] = value
  when 'user'
    method = 'audio.get'
    params['uid'] = ARGV.shift
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

if File.exist? "#{ENV['HOME']}/.config/vkpd.yaml"
  config = YAML.load File.read("#{ENV['HOME']}/.config/vkpd.yaml")
#  params["uid"]=config["user_id"]
  params["access_token"]=config["access_token"]

  connection=Net::HTTP.new("api.vkontakte.ru",443)
  connection.use_ssl=true
  p data=connection.get("/method/#{method}?#{hash_to_params(params)}").body
  response = JSON.parse(data)["response"][1..-1]
  system action_before
  # playlist_file = File.open("vkpd.m3u","w")
  # playlist_file.puts "#EXTM3U\n"
  response.each do |song|
    #  playlist_file.puts "#EXTINF:#{song["duration"]}, #{song["artist"]} - #{song["title"]}"
    #  playlist_file.puts "#{song["url"]}\n"
    system "mpc add #{song["url"]}"
  end
  # playlist_file.close
  system action_after
else
  puts 'Please authenticate. Start vkpd-auth.rb and point your browser to http://localhost.local:4567/'
end
