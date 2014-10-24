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

TODO: Write usage instructions here

API Documentation
-------------

See [RubyDoc](http://rubydoc.info/gems/baler/index)

Contributors
------------

See [Contributing](CONTRIBUTING.md) for details.

License
-------

&copy;2014 Ed Carrel. Released under the MIT License.

See [License](LICENSE) for details.
