$:.unshift File.expand_path("../lib", __FILE__)
require "ec2-mini/version"

Gem::Specification.new do |gem|
  gem.name     = "ec2-mini"
  gem.license  = "MIT"
  gem.version  = EC2Mini::VERSION

  gem.author   = "Masahiro Saito"
  gem.email    = "camelmasa@gmail.com"
  gem.homepage = "http://github.com/camelmasa/ec2-mini"
  gem.summary  = "ec2-mini"

  gem.description = gem.summary
  gem.add_dependency 'aws-sdk'

  gem.executables = "ec2-mini"
  gem.files = Dir["**/*"].select { |d| d =~ %r{^(README|bin/|lib/|spec/)} }
end
