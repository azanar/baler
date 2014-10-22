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
      raise if params.length == 0
      @processed = false
      @params = params
    end

    attr_reader :params
    attr_reader :processed

    def process(foo)
      @processed = true
    end
  end

  class MockResolver
    def initialize(task)
      @task = task
    end

    def build
      @task
    end
  end

  class MockRoute
    def self.tasks
      [MockTask]
    end

    include Hay::Route
  end


  class MockConsumer
    class Factory
      def initialize(observer)
        @consumers = []
        @observer = observer
      end

      attr_reader :consumers

      def new(agent)
        t = MockConsumer.new(agent,@observer)
        @consumers << t
        t
      end
    end

    class Observer
      def initialize
        @mutex = Mutex.new
        @latch = ConditionVariable.new
        @tasks = []
      end

      attr_reader :tasks

      def wait
        @mutex.synchronize {
          @latch.wait(@mutex)
        }
      end

      def <<(task)
        @tasks << task
        if @tasks.length == 10
          @latch.signal
        end
      end
    end
    def tasks
      [MockTask]
    end

    def initialize(agent, observer)
      @observer = observer
      super(agent)
    end

    attr_reader :observer

    def push(task)
      resolved_task = Hay::Task::Resolver.new(task)
      @queue.push(resolved_task)
      @queue.run
      @observer << resolved_task
    end

    include Hay::Consumer
  end

  test "thing" do
    Thread.abort_on_exception = true


    params = 10.times.map do |x|
      {'task' => {'iteration' => x}}
    end

    publisher = Baler::Publisher.new(MockRoute)

    params.each do |p|
      message = OpenStruct.new(payload: {'name' => 'mock_task', 'task' => p}, :destination => MockRoute)
      publisher.publish(message)
    end

    @observer = MockConsumer::Observer.new
    @consumer_factory = MockConsumer::Factory.new(@observer)

    runner = Thread.new do
      consumer = Baler::Consumer.new(@consumer_factory)
      consumer.listen
    end

    @observer.wait

    observed_tasks = @observer.tasks

    assert_equal observed_tasks.length, 10
    observed_tasks.each { |t| 
      assert t.kind_of?(Hay::Task::Decorator) 
      assert t.__getobj__.kind_of?(MockTask) 
      assert t.processed
    }
    assert_equal Set.new(observed_tasks.map(&:params)), Set.new(params)
  end
end
