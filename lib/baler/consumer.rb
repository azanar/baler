require 'hopper'

require 'hopper/channel'
require 'baler/agent'

require 'baler/message/decoder/msgpack'

module Baler 
  # Listens for {Hay::Message} instances on the queue specified by a {Hay::Consumer} implementation
  class Consumer
    # @param consumer [Class] the class of the consumer we are listening on behalf of, which must mix-in Hay::Consumer, and respond to #push
    #
    # @todo At some point, this will take something that builds the consumers, instead of the consumer class.
    def initialize(consumer_klass, opts = {})
      channel = Hopper::Channel.new

      agent = Baler::Agent.new(channel)

      @consumer = consumer_klass.new(agent)

      @listener = channel.queue(@consumer.task_names.first).listener(channel)
    end

    # Listen on behalf of an implementation Hay::Consumer we passed here, and pass received payloads to Hay::Consumer#push
    #
    # @note Will not return under normal circumstances
    def listen
      @listener.listen do |msg|
        begin
          decoded = Baler::Message::Decoder::MsgPack.new(msg)
          @consumer.push(decoded.payload)
          msg.acknowledge
        rescue Exception => e
          Hopper.logger.error "caught exception #{e.message}\n\n#{e.backtrace.join("\n")}"
          msg.reject
        end
      end
    end
  end
end
