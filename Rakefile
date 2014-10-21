require 'pathname'
require 'rubygems/package'
require 'rubygems/installer'

require 'rake/testtask'

task :test do
  Rake::Task['test:unit'].invoke
  Rake::Task['test:integration'].invoke
end

task :build do
  path = Pathname.glob("*.gemspec")
  spec = Gem::Specification.load(path.first.to_s)
  package = Gem::Package.build(spec)
  Gem::Installer.new(package).install
end

task :clean do
  path = Pathname.glob("*.gemspec")
  spec = Gem::Specification.load(path.first.to_s)
  if File.exists?(spec.file_name)
    File.unlink(spec.file_name)
  end
end
  
task :install => :build do
  path = Pathname.glob("*.gemspec")
  spec = Gem::Specification.load(path.first.to_s)
  Gem::Installer.new(spec.file_name).install
end

namespace :test do
  Rake::TestTask.new("integration") do |t|
    t.libs << "test"
    t.libs << "config"
    t.test_files = FileList['test/integration/**/*_test.rb']
    t.verbose = true
  end

  Rake::TestTask.new("unit") do |t|
    t.libs << "test"
    t.libs << "config"
    t.test_files = FileList['test/unit/**/*_test.rb']
    t.verbose = true
  end
end
