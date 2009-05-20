spec = Gem::Specification.new do |s|
    s.name              = 'ActionTimer'
    s.author            = %q(spox)
    s.email             = %q(spox@modspox.com)
    s.version           = '0.0.2'
    s.summary           = %q(Simple timer for a complex world)
    s.platform          = Gem::Platform::RUBY
    s.has_rdoc          = true
    s.rdoc_options      = %w(--title ActionTimer --main README.rdoc --line-numbers --inline-source)
    s.extra_rdoc_files  = %w(README.rdoc LICENSE CHANGELOG)
    s.files             = Dir['**/*']
    s.require_paths     = %w(lib)
    s.add_dependency 'ActionPool'
    s.required_ruby_version = '>= 1.8.6'
    s.homepage          = %q(http://dev.modspox.com/trac/ActionTimer)
    description         = []
    File.open("README.rdoc") do |file|
        file.each do |line|
            line.chomp!
            break if line.empty?
            description << "#{line.gsub(/\[\d\]/, '')}"
        end
    end
    s.description = description[1..-1].join(" ")
end