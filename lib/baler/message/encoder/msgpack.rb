require 'delegate'

require 'hay/message'

module Baler
  class Message
    class Encoder
      class MsgPack < DelegateClass(Hay::Message)
        def initialize(message)
          @message = message
          super
        end

        def payload
          @payload ||= @message.payload.to_msgpack
        end
      end
    end
  end
end
