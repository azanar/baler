require 'hopper'

require 'hopper/channel'
require 'baler/agent'

require 'baler/message/decoder/msgpack'

module Baler 
  class Consumer
    def initialize(consumer_klass, opts = {})
      channel = Hopper::Channel.new

      agent = Baler::Agent.new(channel)

      @consumer = consumer_klass.new(agent)

      @listener = channel.queue(@consumer.task_names.first).listener(channel)
    end

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
