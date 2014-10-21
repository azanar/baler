require File.expand_path('../test_helper', __FILE__)

require 'hay/consumer'
require 'hay/route'
require 'hay/task'
require 'baler/consumer'
require 'baler/publisher'

require 'msgpack'

class Baler::IntegrationTest < Test::Unit::TestCase

  class MockTask
    def self.task_name
      "mock_task"
    end

    include Hay::Task

    def initialize(params = {})
    end

    @@runs = 0

    def self.runs
      @@runs
    end

    def process(foo)
      @@runs += 1
    end
  end

  class MockRoute
    def self.tasks
      [MockTask]
    end

    include Hay::Route
  end

  class MockConsumer
    def tasks
      [MockTask]
    end

    def consumed

    end

    include Hay::Consumer
  end

  test "thing" do
    begin
      Timeout::timeout(1) do
        publisher = Baler::Publisher.new(MockRoute)
        10.times do 
          message = OpenStruct.new(:payload => {'name' => 'mock_task'}, :destination => MockRoute)
          publisher.publish(message)
        end

        consumer = Baler::Consumer.new(MockConsumer)
        consumer.listen
      end
      fail
    rescue Timeout::Error
      if MockTask.runs != 10
        fail
      end
    end
  end
end
