[![Build Status](https://travis-ci.org/azanar/baler.svg)](https://travis-ci.org/azanar/baler)
[![Dependency Status](http://img.shields.io/gemnasium/azanar/baler.svg)](https://gemnasium.com/azanar/baler)
[![Coverage Status](http://img.shields.io/coveralls/azanar/baler.svg)](https://coveralls.io/r/azanar/baler)
[![Code Climate](http://img.shields.io/codeclimate/github/azanar/baler.svg)](https://codeclimate.com/github/azanar/baler)
[![Gem Version](http://img.shields.io/gem/v/baler.svg)](https://rubygems.org/gems/baler)
[![License](http://img.shields.io/:license-mit-blue.svg)](http://azanar.mit-license.org)
[![Badges](http://img.shields.io/:badges-7/7-ff6799.svg)](https://github.com/badges/badgerbadgerbadger)

Baler
======
Baler is a library for managing a pipelined task queue backed by RabbitMQ.

It is the amalgum of two other libraries:

 * [Hopper](https://github.com/azanar/hopper) - https://github.com/azanar/hopper
 * [Hay](https://github.com/azanar/hay) - https://github.com/azanar/hay

Hopper manages binding to a RabbitMQ queue as a producer and/or consumer.

Hay manages making sense out of tasks and subsequent workflows, and is largely agnostic about how these get moved around.

**Baler is the glue that makes RabbitMQ a producer/consumer *for* Hay style tasks.**

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'baler'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install baler

## Usage

A system using Baler does so by instantiating {Publisher}s and {Consumer}s.

### Publisher

A `Publisher` accepts outbound messages and pass them along a `Hay::Route`, and are constructed on demand. 

For example, imagine the following Route:

```ruby
class MyRoute
  # A list of tasks that will have Consumers along this route
  def self.tasks
    [MyTask]
  end

  # Indicating this is a Route, which must happen *after* the task list
  # declaration.
  include Hay::Route
end
```

This is a declaration that `MyRoute` is the proper Route for messages to the
Consumer of `MyTask` instances.

Detailed documentation on `Route` and `Task` classes can be found within the `Hay` project.

With this route, a {Publisher} can be instantiated as follows:

```ruby
publisher = Baler::Publisher.new(MockRoute)
```

Messages can be sent to the Publisher instantiated above by calling
`Publisher#publish` with a `Hay::Message` instance.

```ruby
task = MyTask.new(params)

message = Hay::Message.new(my_task)

publisher.publish(message)
```

### Consumers

Consumers accept inbound messages and act on them. Consumers are typically persistent daemons since 
messages could arrive on the associated queue at any time.

The following code sets up a Consumer for `MyTask`, and sets it listening on
the expected queue.

```ruby
class MyConsumer
  def tasks
    [MyTask]
  end

  include Hay::Consumer
end

consumer = Baler::Consumer.new(MyConsumer)
consumer.listen
```

API Documentation
-------------

See [RubyDoc](http://rubydoc.info/gems/baler/index)

Contributors
------------

See [Contributing](CONTRIBUTING.md) for details.

Todo
----

See [TODO](TODO.md) for

License
-------

&copy;2014 Ed Carrel. Released under the MIT License.

See [License](LICENSE) for details.
