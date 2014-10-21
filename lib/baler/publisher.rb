require 'hopper/channel'
require 'hopper/queue'

require 'baler/message/encoder/msgpack'

module Baler 
  class Publisher
    def initialize(router)
      channel = Hopper::Channel.new

      @hopper = Hopper::Queue.new(router.tasks.first.task_name).publisher(channel)
    end

    def publish(message)
      encoded = Baler::Message::Encoder::MsgPack.new(message)
      @hopper.publish(encoded)
    end
  end
end

