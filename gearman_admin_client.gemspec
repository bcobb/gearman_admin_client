# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'gearman_admin_client/version'

Gem::Specification.new do |spec|
  spec.name          = "gearman_admin_client"
  spec.version       = GearmanAdminClient::VERSION
  spec.authors       = ["Brian Cobb"]
  spec.email         = ["bcobb@uwalumni.com"]
  spec.description   = "A Ruby wrapper around the Gearman admin protocol"
  spec.summary       = "Chat with a gearman server using its admin protocol"
  spec.homepage      = "http://github.com/bcobb/gearman_admin_client"

  spec.files         = Dir['{lib/**/*}'] + %w(README.markdown)
  spec.test_files    = Dir['spec/**/*_spec.rb']
  spec.require_path  = "lib"

  spec.add_development_dependency "bundler"
  spec.add_development_dependency "rspec"
  spec.add_development_dependency "gearmand_control"
  spec.add_runtime_dependency "virtus"
  spec.add_runtime_dependency "celluloid"
  spec.add_runtime_dependency "celluloid-io"
end
