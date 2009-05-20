spec = Gem::Specification.new do |s|
    s.name              = 'ActionTimer'
    s.author            = %q(spox)
    s.email             = %q(spox@modspox.com)
    s.version           = '0.0.2'
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
    description         = []
    File.open("README") do |file|
        file.each do |line|
            line.chomp!
            break if line.empty?
            description << "#{line.gsub(/\[\d\]/, '')}"
        end
    end
    s.description = description[1..-1].join(" ")
end