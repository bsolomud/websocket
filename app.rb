require 'em-websocket'
require 'amqp'
require 'json'

HOST = 'localhost'

class Message
  attr_reader :sender, :receiver, :text

  def initialize(sender, receiver, text)
    @sender = sender
    @receiver = receiver
    @text = text
  end

  def to_json
    { sender: @sender, receiver: @receiver, text: @text }.to_json
  end
end

def generate_queue_name(value)
  value.tr(' -_', '').downcase
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

      puts 'Client is connected'

      @connection = AMQP.connect host: HOST
      @channel = AMQP::Channel.new @connection
      @exchange = @channel.topic 'demo'

      @queue_is_subscribed = false
    }

    ws.onmessage do |msg|

      msg = JSON.parse msg

      p "======================= MSG: #{msg}"

      # @exchange ||= if @channel_type == 'direct'
      #                 @channel.default_exchange
      #               elsif @channel_type = 'fanout'
      #                 @channel.fanout 'centre.ua'
      #               end

      if msg['sender']
        @queue_name = generate_queue_name msg['sender']

        unless @queue_is_subscribed
          # queue = if @channel_type == 'direct'
          #           @channel.queue(@queue_name)
          #         elsif @channel_type == 'fanout'
          #           @channel.queue(@queue_name).bind(@exchange)
          #         end
          @queue = @channel.queue @queue_name

          @queue.subscribe do |payload|
            ws.send payload
          end

          @queue_is_subscribed = true
        end

        @users << msg['sender'] unless @users.include? msg['sender']

        users = { users: @users }

        @web_sockets.each do |web_socket|
          web_socket.send users.to_json
        end
      end

      @receiver_routing_key = msg['receiver'] if msg['receiver']

      @messages << msg['text'] if msg['text']

      if msg['sender'] && msg['receiver'] && msg['text']
        @msg = Message.new msg['sender'], msg['receiver'], msg['text']

        @exchange.publish @msg.to_json, routing_key: @queue_name
        # if @channel_type == 'direct'
        @exchange.publish @msg.to_json, routing_key: @receiver_routing_key
        # end
      end
    end

    ws.onclose do
      puts 'Client is disconnected'
      @web_sockets.delete ws
      @connection.close
    end
  end
}
