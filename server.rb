
require 'rubygems'
require 'em-websocket'

MAX_LOG = 100

EM::run do

  puts 'server start'
  @channel = EM::Channel.new
  @logs = Array.new
  @channel.subscribe{|mes|
    @logs.push mes
    @logs.shift if @logs.size > MAX_LOG
  }

  EM::WebSocket.start(:host => "0.0.0.0", :port => 8080) do |ws|
    ws.onopen{
      sid = @channel.subscribe{|mes|
        ws.send(mes)
      }
      puts "<#{sid}> connected!!"
      @logs.each{|mes|
        ws.send(mes)
      }
      @channel.push("hello <#{sid}>")

      # channel登録時のidを使うためにonopen内で他のイベント登録を済ませる
      ws.onmessage{|mes|
        puts "<#{sid}> #{mes}"
        @channel.push("<#{sid}> #{mes}")
      }

      ws.onclose{
        puts "<#{sid}> disconnected"
        @channel.unsubscribe(sid)
        @channel.push("<#{sid}> disconnected")
      }
    }
  end

  EM::defer do
    loop do
      puts Time.now.to_s
      @channel.push Time.now.to_s
      sleep 60*60*3 # 3時間ごと
    end
  end
end

