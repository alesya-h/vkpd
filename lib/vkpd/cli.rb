module Vkpd
  class CLI
    # main CLI method
    def main
      mpd = MPD.new 'localhost'
      mpd.connect
      method = "audio.search"
      params = {}
      do_clear = true
      do_play = true
      params["auto_complete"] = '1'
      player = ENV['VKPD_PLAYER'].to_sym || :mpd
      random = false
  
      if ARGV.empty?
        ARGV.push "-h"
      end
  
      while ARGV.size > 0
        current = ARGV.shift
        case current
        when '-h','--help'
          filename = Pathname(__FILE__).dirname+'../../README'
          puts File.read(filename)
          exit 0
        when '-v', '--verbose'
          @verbose = true
        when '-r', '--random'
          random = true
        when '-p', '--player', /^--player=\w+$/
          player = current.include?("=") ? current.match(/=(.*)/)[1] : ARGV.shift
          player = player.to_sym
        when '-c', '--count', /^--count=\d+$/
          value = current.include?("=") ? current.match(/=(.*)/)[1] : ARGV.shift
          params["count"]  = value
        when '-o', '--offset', /^--offset=\d+$/
          value = current.include?("=") ? current.match(/=(.*)/)[1] : ARGV.shift
          params["offset"] = value
        when '-s', '--sort', /^--sort=\d+$/
          value = current.include?("=") ? current.match(/=(.*)/)[1] : ARGV.shift
          params["sort"] = value
        when '-nf','--no-fix', '--exact'
          params["auto_complete"] = '0'
        when '--https'
          params['https'] = '1'
        when 'user'
          method = 'audio.get'
          if !ARGV.empty? and ARGV.first.match(/^\d+$/)
            params['uid'] = ARGV.shift
          else
            params['uid'] = Vkpd::config["user_id"]
          end
        when 'group'
          method = 'audio.get'
          params['gid'] = ARGV.shift
        when 'add'
          do_clear = false
          do_play = false
        when 'auth'
          Thread.new do
            sleep 1
            Launchy.open('http://localhost.localdomain:4567')
          end
          Vkpd::Auth.run!
        when 'play'
          # do nothing
        else
          params["q"]=ARGV.unshift(current).join(" ")
          ARGV.clear
        end
      end

      params["access_token"]=Vkpd::config["access_token"]

      response = make_vk_request(method,params)
      if method.match /search/
        response.shift
      end

      response = response.shuffle if random

      case player
      when :mpd
        mpd.clear if do_clear
        response.each do |song|
          puts song if @verbose
          mpd.add song["url"]
        end
        mpd.play if do_play
      when :mplayer, :mpv
        catch :stop do
          response.each do |song|
            ap song
            system "#{player} -cache 8192 -cache-min 2 #{song['url']}"
            begin
              Timeout::timeout 0.25 do
                case key = STDIN.getch
                when 'q' then throw :stop
                end
              end
            rescue Timeout::Error
              # do nothing
            end
          end
        end
      end
    end

    private
  
    # Makes string with params for http request from hash
    def hash_to_params(hash)
      hash.map{|k,v| "#{k}=#{CGI.escape(v.to_s)}"}.join("&")
    end

    def make_vk_request(method, params)
      connection=Net::HTTP.new("api.vk.com",443)
      connection.use_ssl=true
      data = JSON.parse connection.get("/method/#{method}?#{hash_to_params(params)}").body
      p data if @verbose
      while data['error'] and data['error']['error_code'].to_i == 14
        p data['error'] if @verbose
        captcha_sid = data['error']['captcha_sid']
        captcha_img = data['error']['captcha_img']
        system "display #{captcha_img} &"
        print "captcha: "
        captcha_key = gets.chomp
        params['captcha_sid'] = captcha_sid
        params['captcha_key'] = captcha_key
        data = JSON.parse connection.get("/method/#{method}?#{hash_to_params(params)}").body
        p data if @verbose
      end
      data["response"]
    end

  end
end
