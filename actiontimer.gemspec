spec = Gem::Specification.new do |s|
    s.name              = 'ActionTimer'
    s.author            = %q(spox)
    s.email             = %q(spox@modspox.com)
    s.version           = '0.0.1'
    s.summary           = %q(Simple timer for a complex world)
    s.platform          = Gem::Platform::RUBY
    s.has_rdoc          = true
    s.files             = Dir['**/*']
    s.rdoc_options      = %w(--title ActionTimer --main README --line-numbers)
    s.extra_rdoc_files  = %w(README)
    s.require_paths     = %w(lib)
    s.add_dependency 'ActionPool'
    s.required_ruby_version = '>= 1.8.6'
    s.homepage          = %q(http://dev.modspox.com/trac/ActionTimer)
    s.description       = []
end