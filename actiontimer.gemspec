spec = Gem::Specification.new do |s|
  s.name        = 'actiontimer'
  s.author      = 'spox'
  s.email       = 'spox@modspox.com'
  s.version       = '0.2.1'
  s.summary       = 'Simple timer for a complex world'
  s.platform      = Gem::Platform::RUBY
  s.has_rdoc      = true
  s.rdoc_options    = %w(--title ActionTimer --main README.rdoc --line-numbers --inline-source)
  s.extra_rdoc_files  = %w(README.rdoc LICENSE CHANGELOG)
  s.files       = Dir['**/*']
  s.require_paths   = %w(lib)
  s.add_dependency 'actionpool', '~> 0.2.3'
  s.add_dependency 'splib', '~> 1.4'
  s.required_ruby_version = '>= 1.8.6'
  s.homepage      = 'http://github.com/spox/actiontimer'
  s.description     = 'ActionTimer is a simple timer for recurring actions. It supports single and recurring actions with an easy to use API.'
end
