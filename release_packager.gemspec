require_relative 'lib/release_packager/version'

Gem::Specification.new do |spec|
  spec.name          = 'release_packager'
  spec.version       = ReleasePackager::VERSION
  spec.authors       = ['ATEX']
  spec.summary       = 'Git-based release archive packager with whitelist filtering'
  spec.description   = 'Creates ZIP release archives from Git repositories with ' \
                        'configurable file whitelisting, exclusions, and extra file injection.'
  spec.license       = 'MIT'
  spec.required_ruby_version = '>= 3.0'

  spec.files = Dir['lib/**/*.rb']
  spec.require_paths = ['lib']

  spec.add_dependency 'rake', '>= 12.0'

  spec.add_development_dependency 'rspec', '~> 3.0'
end
