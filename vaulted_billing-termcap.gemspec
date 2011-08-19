lib = File.expand_path('../lib/', __FILE__)
$:.unshift lib unless $:.include?(lib)

require 'vaulted_billing/termcap/version'

Gem::Specification.new do |s|
  s.name = 'vaulted_billing-termcap'
  s.version = VaultedBilling::Termcap::Version
  s.platform = Gem::Platform::RUBY
  s.authors = ['Adam Fortuna']
  s.email = ['adam@envylabs.com']
  s.homepage = 'http://github.com/envylabs/vaulted_billing-termcap'
  s.summary = 'A library for working with terminal capture gateways.'
  s.description = 'Methods specific to gateways that use terminal capture.'
  s.required_rubygems_version = '>= 1.3.6'

  s.add_dependency 'vaulted_billing', '~>1.1'
  
  s.add_development_dependency 'rspec', '~>2.4'
  s.add_development_dependency 'vcr', '~>1.7'
  s.add_development_dependency 'webmock', '~>1.6'
  s.add_development_dependency 'factory_girl', '~>1.3'
  s.add_development_dependency 'faker', '~>0.9'
  s.add_development_dependency 'rake', '~>0.9'
  s.add_development_dependency 'watchr'
  s.add_development_dependency 'open4'

  s.files = Dir.glob("lib/**/*") + %w(README.md)
  s.require_path = 'lib'
end
