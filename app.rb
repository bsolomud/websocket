require 'eventmachine'
require 'em-websocket'


EM.run {
  EM::WebSocket.start({
                          host: "localhost",
                          port: 8187,
                          debug: true

                      }) do |ws|
    ws.onopen {
      puts "Socket connection start"

      ws.send "You are now connected"
    }

    ws.onmessage { |msg|
      ws.send "Pong #{msg}"
    }

    ws.onclose {
      puts "Socket connection closed"
      ws.close
    }
  end
}