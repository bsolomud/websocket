require 'em-websocket'
require 'amqp'

HOST = 'localhost'

def deconstruct!(message)
  @key = message.slice 0, message.index(':')
  @value = message.slice message.index(':') + 1, message.size - 1
end

def generate_queue_name(value)
  value.tr(' ', '_').tr('-', '_').downcase
end

EM.run {

  @web_sockets = []
  @users = []
  @messages = []

  EM::WebSocket.start(host: HOST,
                      port: 8187,
                      debug: true) do |ws|

    ws.onopen {
      @web_sockets << ws

      puts "Client is connected"

      @connection ||= AMQP.connect host: HOST
      @channel ||= AMQP::Channel.new @connection

      # ws.send @chat_text
    }

    ws.onmessage do |msg|
      p "======================= MSG: #{msg}"

      deconstruct! msg

      case @key
        when 'user_name'
          @user_name = @value
          @users << @user_name unless @users.include? @user_name
          ws.send "users:#{@users.join ', '}"
        when 'to'
          @queue_name = generate_queue_name @value
        when 'message'
          # AMQP setup
          @queue = @channel.queue @queue_name
          @exchange ||= @channel.direct ''
          @queue.subscribe do |payload|
            ws.send "message:#{payload}"
          end

          @exchange.publish "user_name:#{@user_name}", routing_key: @queue_name
          @exchange.publish "message:#{@message}", routing_key: @queue_name
          @messages << @value
      end
    end

    ws.onclose do
      puts "Client is disconnected"
      @connection.close
      @web_sockets.delete ws
    end
  end
}
