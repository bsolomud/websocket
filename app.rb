require 'eventmachine'
require 'em-websocket'

EM.run {
  @sockets = []
  EM::WebSocket.start({
                          host: 'localhost',
                          port: 8187,
                          debug: true

                      }) do |ws|
    ws.onopen {
      @sockets << ws
      # puts "Socket connection is started"
      # ws.send @chat_text
    }

    ws.onmessage { |msg|
      @sockets.each do |socket|
        socket.send msg
      end
    }

    ws.onclose do
      puts "Socket connection is closed"
      @sockets.delete ws
    end

    # def ws_open(sock)
    #   @sockets << sock
    #   p "SOCKETSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSS #{@sockets}"
    # end
    #
    # def ws_message
    #
    # end
  end
}
