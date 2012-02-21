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
params["auto_complete"] = '1'

if ARGV.empty?
  ARGV.push "-h"
end

while ARGV.size > 0
  current = ARGV.shift
  case current
  when '-h','--help'
    puts man=<<EOF
vkpd [options] [search request]

Options:

  -c, --count=n
       Limit songs count
  -o, --offset=n
       Drop first n results
  -s, --sort=n
       Sort by: 0 - popularity, 1 - length, 2 - upload date
  -f, --fix
       Try to fix typos
  user [user_id]
       Load user songs. If user_id not supplied use current user's id
  group <group_id>
       Load group songs
  add
       Add songs to current playlist instead of replacing it

Some examples:
        vkpd Beatles # replaces current mpd playlist with The Beatles' songs and starts playing
        vkpd play Beatles # the same
        vkpd add Beatles # adds found songs to playlist and starts playing
        vkpd -c 5 Beatles # get just first five search results
        vkpd -c 5 -o 5 beatles # get second five results
        vkpd --count 5 --offset=5 beatles # the same
        vkpd user 3885655 # plays user's songs
        vkpd user 3885655 -c 3 # plays last three songs added by user
        vkpd user # current user's songs
        vkpd user -c 1 # current user's last added song
        vkpd group 1 # plays songs from group with id = 1
        vkpd --fix Beetles # fixes typo and plays The Beatles
        vkpd -f Beetles # same as above
        vkpd -s 1 Beatles # sorted by length. 0 to sort by popularity, 2 to sort by upload date
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
  when '-nf','--no-fix', '--exact'
    params["auto_complete"] = '0'
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
  puts 'Please authenticate. Start vkpd-auth.rb and point your browser to http://localhost.localdomain:4567/'
  exit 1
end

config = YAML.load File.read("#{ENV['HOME']}/.config/vkpd.yaml")
params["access_token"]=config["access_token"]

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
