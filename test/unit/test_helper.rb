if ENV["ENABLE_SIMPLE_COV"]
  require 'simplecov'
  require File.expand_path('../../simplecov_helper', __FILE__)
  SimpleCov.start 'pocketchange' do
    add_filter 'test'
  end
end

require 'test/unit'
require 'active_support/test_case'

ENV["WARREN_ENV"] = "test"

require 'mocha/setup'

module TestHelper
end
