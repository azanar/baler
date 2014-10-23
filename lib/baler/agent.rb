module Baler 
  # Passes on {Hay::Message} instances to the appropriate {Baler::Publisher} based on the
  # destination specified in the message
  class Agent
    # @param channel [Hopper::Channel] the channel to publishes messages to.
    def initialize(channel)
      @channel = channel
      @publishers = {}
    end

    # @param message [Hay::Message] the message to get published
    def publish(message)
      endpoint = message.destination
      @publishers[endpoint] ||= Baler::Publisher.new(endpoint, @channel)
    end
  end
end

