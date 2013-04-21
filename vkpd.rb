#!/usr/bin/env ruby
require "net/http"
require "net/https"
require "cgi"
require "yaml"
require "json"
require "optparse"

params = {}
action_after  = 'mpc play'
params["auto_complete"] = '1'

module VKPD; end
VKPD.instance_eval do

  def hash_to_params(hash)
    hash.map{|k,v| "#{k}=#{CGI.escape(v.to_s)}"}.join("&")
  end
  def query_vk method, params
    params["access_token"]=config["access_token"]
    connection=Net::HTTP.new("api.vk.com",443)
    connection.use_ssl=true
    data=connection.get("/method/#{method}?#{hash_to_params(params)}").body
    response = JSON.parse(data)["response"]
    if method.match /search/
      response.shift
    end
    response.map{ |song| song["url"] }
  end
  def config
    unless File.exist? "#{ENV['HOME']}/.config/vkpd.yaml"
      puts 'Please authenticate. Start vkpd-auth.rb and point your browser to http://localhost.localdomain:4567/'
      exit 1
    end
    $config ||= YAML.load File.read("#{ENV['HOME']}/.config/vkpd.yaml")
  end

  def show_help
    filename = "#{__dir__}/README"
    puts File.read(filename)
  end
  def mpd_add song_url
    execute "mpc add #{song_url}"
  end
  def mpd_clear
    execute "mpc clear"
  end
  def add_songs songs
    songs.each{ |song| mpd_add song }
  end
  def replace_songs songs
    mpd_clear
    add_songs songs
  end
  def mpd_play
    execute "mpc clear"
  end
    
  def run options
    # case current
    # when '-h','--help'
    #   show_help
    #   return
    # when '-d', '--debug'
    #   $debug = true
    # when '-c', '--count', /^--count=\d+$/
    #   value = current.include?("=") ? current.match(/=(.*)/)[1] : args.shift
    #   params["count"]  = value
    # when '-o', '--offset', /^--offset=\d+$/
    #   value = current.include?("=") ? current.match(/=(.*)/)[1] : args.shift
    #   params["offset"] = value
    # when '-s', '--sort', /^--sort=\d+$/
    #   value = current.include?("=") ? current.match(/=(.*)/)[1] : args.shift
    #   params["sort"] = value
    # when 'user'
    #   method = 'audio.get'
    #   if !args.empty? and args.first.match(/^\d+$/)
    #     params['uid'] = args.shift
    #   else
    #     params['uid'] = config["user_id"]
    #   end
    # when 'group'
    #   method = 'audio.get'
    #   params['gid'] = args.shift
    # when 'add'
    #   action_before = ''
    #   action_after = ''
    # when '-nf','--no-fix', '--exact'
    #   params["auto_complete"] = '0'
    # when 'play'
    #   # do nothing
    # else
    #   params["q"]=args.unshift(current).join(" ")
    #   args.clear
    # end
  end

  def execute(*args)
    if $debug
      puts(*args)
    else
      system(*args)
    end
  end

end

o = {sort: 0, verbose: false, offset: 0}

OptionParser.new do |opts|
  opts.banner = "Usage: vkpd [options] [search request]"
  opts.on("-v", "--verbose",
          "Run verbosely"){            |arg| o[:verbose] = arg }
  opts.on("-u", "--vk-user name",
          "Play vk user's songs"){     |arg| o[:vk_user] = arg }
  opts.on("-l", "--lastfm-user name",
          "Play lastfm user's songs"){ |arg| o[:lastfm_user] = arg }
  opts.on("-c", "--count n",
          "Add no more than n songs"){ |arg| o[:limit] = arg }
  opts.on("-o", "--offset n",
          "Add no more than n songs"){ |arg| o[:offset] = arg }
  opts.on("-s", "--sort",
          "Results sorting order",
          "(0 - popularity, 1 - length, 2 - upload date)"){ |arg| o[:sort] = arg }
  opts.on_tail("-h", "--help", "Show this message"){ puts opts; exit }
end.parse!

VKPD.run(o)
