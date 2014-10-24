require 'baler/consumer'


# Baler is a library for managing a pipelined worker queue backed by RabbitMQ.
#
# See more in the {file:README.md README}
module Baler
  # Listen on behalf of an implementation Hay::Consumer we passed here, and pass received payloads to Hay::Consumer#push
  #
  # @param consumer [Class] the class of the consumer we are listening on behalf of, which must mix-in Hay::Consumer, and respond to #push
  #
  # @todo At some point, this will take something that builds the consumers, instead of the consumer class.
  #
  def self.listen_to(consumer)
    baler_consumer = Baler::Consumer.new(consumer)

    baler_consumer.listen

    nil
  end
end
