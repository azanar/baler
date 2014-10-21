require 'baler/consumer'
module Baler
  def self.listen_to(consumer)
    baler_consumer = Baler::Consumer.new(consumer)

    baler_consumer.listen
  end
end
