module Baler 
  class Agent
    def initialize(channel)
      @channel = channel
      @publishers = {}
    end

    def publish(message)
      endpoint = message.destination
      @publishers[endpoint] ||= Baler::Publisher.new(endpoint, @channel)
    end
  end
end

