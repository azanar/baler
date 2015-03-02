require File.expand_path('../test_helper', __FILE__)


require 'hay/consumer'
require 'hay/route'
require 'hay/task'
require 'baler/consumer'
require 'baler/publisher'

class Baler::IntegrationTest < Test::Unit::TestCase
  class TaskFactory
    def initialize(name, nxt = [])
      @name = name
      @klass = Class.new do
        include Hay::Task

        def initialize(params)
          @params = params
        end

        def dehydrate
          @params.to_h
        end

        attr_reader :params

        def process(agent)
          raise NotImplementedError.new("This should be defined in the tests as an expectation.")
        end
      end

      @klass.instance_eval do
        define_singleton_method(:task_name) do
          name
        end
      end
      @flow = Hay::Task::Flow.new
      @flow.push(nxt.map(&:new).map(&:to_hay))
    end

    attr_reader :klass

    def task_name
      @name
    end

    def tasks
      [@klass]
    end

    class Expector
      def initialize(factory, expector)
        @factory = factory
        @expector = expector
      end

      def task_name
        @factory.task_name
      end

      def tasks
        @factory.tasks
      end

      def new(params = {})
        t = @factory.new(params)
        @expector.call(t)
        t
      end
    end

    def expector(expector)
      Expector.new(self, expector)
    end

    def new(params = {})
      t = @klass.new(params).to_hay

      t.flow = @flow

      t
    end
  end

  class Route
    class Factory
      def initialize(task_factories)
        @tasks = task_factories.map(&:tasks).flatten
      end

      attr_reader :tasks

      def new(agent)
        Route.new(@tasks, agent)
      end
    end

    def initialize(tasks, agent)
      @tasks = tasks
      super(agent)
    end

    include Hay::Route

    attr_reader :tasks

  end

  class MockConsumer
    class Factory
      def initialize(route, observer)
        @consumers = []
        @observer = observer
        @route = route
      end

      attr_reader :observer
      attr_reader :consumers 

      def new(agent)
        t = MockConsumer.new(agent,@route, @observer)
        @consumers << t
        t
      end
    end

    class Observer
      def initialize
        @mutex = Mutex.new
        @latch = ConditionVariable.new
        @tasks = []
        @failed = []
      end

      attr_reader :tasks

      def wait
        @mutex.synchronize {
          @latch.wait(@mutex, 2)
        }
      end

      def seen
        @tasks.length + @failed.length
      end

      def <<(task)
        @tasks << task
        check
      end

      def failed(task)
        @failed << task
        check
      end

      def check
        if seen >= 20 
          @latch.signal
        end
      end
    end

    def tasks
      @route.tasks
    end

    def initialize(agent, route, observer)
      @observer = observer
      @route = route
      super(agent)
    end

    attr_reader :observer

    def ours?(task)
      super(task)
    end

    def push(task)
      resolved_task = Hay::Task::Resolver.new(task)

      begin
        @queue.push(resolved_task)
        @queue.run
        @observer << resolved_task

      rescue Exception => e
        @observer.failed(resolved_task)
        raise e
      end
    end

    include Hay::Consumer
  end

  class Instance
    def initialize(params)
      @task_names = params.fetch('task_names')
      @flows = params['flow'] || {}
      @expectation = params.fetch('expectation')
    end

    def task_factories
      @task_factories ||= @task_names.names.map do |name|
                            TaskFactory.new(name, )
      end
    end

    def flow(task)
    end

    def route_factory
      @route ||= Route::Factory.new(@tasks)
    end

    def observer 
      @observer ||= MockConsumer::Observer.new
    end

    def consumer_factory
      @consumer_factory ||= MockConsumer::Factory.new(route_factory, observer)
    end

    def run_consumer
      Hay::Tasks.register(expector)
      Hay::Task::Hydrators.register(expector, Hay::Task::Hydrator)

      consumer_factory = MockConsumer::Factory.new(route_factory, observer)

      Thread.new do
        consumer = Baler::Consumer.new(consumer_factory)
        consumer.listen
      end
    end
  end

  test "simple publishing and consuming same route" do
    Thread.abort_on_exception = true

    params = 10.times.map do |x|
      {'iteration' => x}
    end

    instance = Instance.new(:task_names => ['a'])

    expector = instance.task_factory.expector(proc {|t| 
      t.expects(:process)
    })


    route_factory = Route::Factory.new([expector])

    publisher = Baler::Publisher.new(instance.route_factory)

    params.each do |p|
      message = Hay::Message.new(task_factory.new(p))
      publisher.publish(message)
    end

    observer = instance.observer

    observer.wait

    observed_tasks = observer.tasks

    assert_equal observed_tasks.length, 10
    observed_tasks.each { |t| 
      assert t.kind_of?(Hay::Task::Decorator)
      assert t.__getobj__.kind_of?(task_factory.klass)
    }
    assert_equal Set.new(observed_tasks.map(&:params)), Set.new(params)
  end

  test "consumer on a single route publishes more work" do
    Thread.abort_on_exception = true

    params = 10.times.map do |x|
      {'iteration' => x}
    end
    bar_task_factory = TaskFactory.new('b')

    bar_expector = bar_task_factory.expector(proc {|t| t.expects(:process)})

    baz_task_factory = TaskFactory.new('c', [bar_task_factory])

    baz_expector = baz_task_factory.expector(proc {|t|
      t.expects(:process).with {|resulter| 
        res = t.params.merge({"foo" => "bar"})
        resulter.submit("task" => res)
      }
    })

    Hay::Tasks.register(bar_expector)
    Hay::Task::Hydrators.register(bar_expector, Hay::Task::Hydrator)


    Hay::Tasks.register(baz_expector)
    Hay::Task::Hydrators.register(baz_expector, Hay::Task::Hydrator)

    route_factory = Route::Factory.new([bar_expector,baz_expector])

    publisher = Baler::Publisher.new(route_factory)

    params.each do |p|
      message = Hay::Message.new(baz_task_factory.new(p))
      publisher.publish(message)
    end

    observer = MockConsumer::Observer.new
    consumer_factory = MockConsumer::Factory.new(route_factory, observer)

    Thread.new do
      consumer = Baler::Consumer.new(consumer_factory)
      consumer.listen
    end

    observer.wait

    observed_tasks = observer.tasks

    assert_equal observed_tasks.length, 20

    bar_observed_tasks = observed_tasks.select {|t| t.__getobj__.kind_of?(bar_task_factory.klass)}
    baz_observed_tasks = observed_tasks.select {|t| t.__getobj__.kind_of?(baz_task_factory.klass)}

    assert_equal bar_observed_tasks.length, 10
    assert_equal baz_observed_tasks.length, 10

    assert_equal Set.new(baz_observed_tasks.map(&:params)), Set.new(params)
    assert_equal Set.new(bar_observed_tasks.map(&:params)), Set.new(params.map {|p| p.merge({"foo" => "bar"})})
  end

  test "consumer on a many routes publishes more work" do
    Thread.abort_on_exception = true

    params = 10.times.map do |x|
      {'iteration' => x}
    end

    bar_task_factory = TaskFactory.new('bar')

    bar_expector = bar_task_factory.expector(proc {|t| t.expects(:process)})

    baz_task_factory = TaskFactory.new('baz', [bar_task_factory])

    baz_expector = baz_task_factory.expector(proc {|t|
      t.expects(:process).with {|resulter| 
        res = t.params.merge({"foo" => "bar"})
        resulter.submit("task" => res)
      }
    })

    Hay::Tasks.register(bar_expector)
    Hay::Task::Hydrators.register(bar_expector, Hay::Task::Hydrator)


    Hay::Tasks.register(baz_expector)
    Hay::Task::Hydrators.register(baz_expector, Hay::Task::Hydrator)

    bar_route_factory = Route::Factory.new([bar_expector])
    Hay::Routes.register(bar_route_factory)

    baz_route_factory = Route::Factory.new([baz_expector])
    Hay::Routes.register(baz_route_factory)

    publisher = Baler::Publisher.new(baz_route_factory)

    params.each do |p|
      message = Hay::Message.new(baz_task_factory.new(p))
      publisher.publish(message)
    end

    bar_observer = MockConsumer::Observer.new
    bar_consumer_factory = MockConsumer::Factory.new(bar_route_factory, bar_observer)

    Thread.new do
      consumer = Baler::Consumer.new(bar_consumer_factory)
      consumer.listen
    end

    baz_observer = MockConsumer::Observer.new
    baz_consumer_factory = MockConsumer::Factory.new(baz_route_factory, baz_observer)

    Thread.new do
      consumer = Baler::Consumer.new(baz_consumer_factory)
      consumer.listen
    end

    bar_observer.wait
    baz_observer.wait

    bar_observed_tasks = bar_observer.tasks
    baz_observed_tasks = baz_observer.tasks

    assert_equal bar_observed_tasks.length, 10
    assert_equal baz_observed_tasks.length, 10

    bar_observed_tasks.each {|t| assert t.__getobj__.kind_of?(bar_task_factory.klass)}
    baz_observed_tasks.each {|t| assert t.__getobj__.kind_of?(baz_task_factory.klass)}

    assert_equal Set.new(baz_observed_tasks.map(&:params)), Set.new(params)
    assert_equal Set.new(bar_observed_tasks.map(&:params)), Set.new(params.map {|p| p.merge({"foo" => "bar"})})
  end
end
