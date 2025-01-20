Gem::Specification.new do |s|
  s.name              = 'oxidized-script'
  s.version           = '0.6.0'
  s.licenses          = %w[Apache-2.0]
  s.platform          = Gem::Platform::RUBY
  s.authors           = ['Saku Ytti']
  s.email             = %w[saku@ytti.fi]
  s.homepage          = 'http://github.com/ytti/oxidized-script'
  s.summary           = 'cli + library for scripting network devices'
  s.description       = 'rancid clogin-like script to push configs to devices + library interface to do same'
  s.files             = `git ls-files`.split("\n")
  s.executables       = %w[oxs]
  s.require_path      = 'lib'

  s.add_runtime_dependency 'oxidized',    '~> 0.28'
  s.add_runtime_dependency 'slop',        '~> 4.6'
  s.add_development_dependency 'bundler', '~> 2.0'
  s.add_development_dependency 'rake',    '~> 10.0'
  s.add_development_dependency 'rubocop', '~> 1.70.0'
end
