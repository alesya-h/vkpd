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


def config
  unless File.exist? "#{ENV['HOME']}/.config/vkpd.yaml"
    puts 'Please authenticate. Start vkpd-auth.rb and point your browser to http://localhost.localdomain:4567/'
    exit 1
  end
  @config ||= YAML.load File.read("#{ENV['HOME']}/.config/vkpd.yaml")
end

while ARGV.size > 0
current = ARGV.shift
  case current
  when '-h','--help'
    filename = `dirname #{`readlink -f #{$0}`}`.chomp+"/README"
    puts File.read(filename)
    exit 0
  when '-d', '--debug'
    $debug  = true
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

def run(*args)
  if $debug
    puts(*args)
  else
    system(*args)
  end
end

def hash_to_params(hash)
  hash.map{|k,v| "#{k}=#{CGI.escape(v.to_s)}"}.join("&")
end

params["access_token"]=config["access_token"]

connection=Net::HTTP.new("api.vk.com",443)
connection.use_ssl=true
data=connection.get("/method/#{method}?#{hash_to_params(params)}").body
response = JSON.parse(data)["response"]
if method.match /search/
  response.shift
end
run action_before
response.each do |song|
  run "mpc add #{song["url"]}"
end
run action_after
