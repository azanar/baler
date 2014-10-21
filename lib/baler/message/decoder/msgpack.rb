require 'delegate'

require 'hopper/message'
require 'hay/task/resolvers'

module Baler
  class Message
    class Decoder
      class MsgPack < DelegateClass(Hopper::Message)
        def initialize(message)
          @message = message
          super
        end

        def payload
          @payload ||= ::MessagePack.unpack(@message.message.payload)
        end
        Hay::Task::Resolvers.register(self, Hay::Task::Resolver::Task)
      end
    end
  end
end
