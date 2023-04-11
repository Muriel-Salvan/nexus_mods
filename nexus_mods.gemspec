require "#{__dir__}/lib/nexus_mods/version"

Gem::Specification.new do |spec|
  spec.name = 'nexus_mods'
  spec.version = NexusMods::VERSION
  spec.authors = ['Muriel Salvan']
  spec.email = ['muriel@x-aeon.com']
  spec.license = 'BSD-3-Clause'
  spec.required_ruby_version = '>= 3.1'

  spec.summary = 'Access NexusMods REST API from Ruby'
  spec.homepage = 'https://github.com/Muriel-Salvan/nexus_mods'

  spec.metadata['homepage_uri'] = spec.homepage
  spec.metadata['rubygems_mfa_required'] = 'true'

  spec.files = Dir['*.md'] + Dir['{bin,docs,examples,lib,spec,tools}/**/*']
  spec.executables = Dir['bin/**/*'].map { |exec_name| File.basename(exec_name) }
  spec.extra_rdoc_files = Dir['*.md'] + Dir['{docs,examples}/**/*']
  spec.require_paths = ['lib']

  # HTTP API library
  spec.add_dependency 'faraday', '~> 2.7'
  # Make conditional memoization for queries to NexusMods API
  spec.add_dependency 'cacheable', '~> 2.0'

  # Development dependencies (tests, build)
  # Test framework
  spec.add_development_dependency 'rspec', '~> 3.12'
  # Mock HTTP calls
  spec.add_development_dependency 'webmock', '~> 3.18'
  # Lint checker
  spec.add_development_dependency 'rubocop', '~> 1.48'
  # Lint checker for rspec
  spec.add_development_dependency 'rubocop-rspec', '~> 2.19'
  # Automatic semantic releasing
  spec.add_development_dependency 'sem_ver_components', '~> 0.3'
end
