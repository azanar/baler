require 'hopper/channel'
require 'hopper/queue'

require 'baler/message/encoder/msgpack'


module Baler
  # Accepts {Hay::Message}s for the the queue at destination specified by {Hay::Router}
  class Publisher
    # @param router [Hay::Router] router this will send messages to.
    def initialize(router, channel = Hopper::Channel.new)
      @hopper = Hopper::Queue.new(router.tasks.first.task_name).publisher(channel)
    end

    # Publishes a message passed to the route specified.
    #
    # @param message [Hay::Message] the message to be published
    def publish(message)
      encoded = Baler::Message::Encoder::MsgPack.new(message)
      @hopper.publish(encoded)
    end
  end
end

