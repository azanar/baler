if ENV["COVERAGE"]
  require 'coveralls'
  require 'codeclimate-test-reporter'
  require 'simplecov'
  SimpleCov.start do
    add_group "Lib", "lib"
    add_filter "/test/"
    command_name "Unit Tests"
    formatter SimpleCov::Formatter::MultiFormatter[
      SimpleCov::Formatter::HTMLFormatter,
      Coveralls::SimpleCov::Formatter,
      CodeClimate::TestReporter::Formatter
    ]
  end
end

require 'test/unit'

ENV["BALER_ENV"] = "test"

require 'mocha/setup'

module TestHelper
end
