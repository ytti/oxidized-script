Gem::Specification.new do |s|
  s.name              = 'oxidized-script'
  s.version           = '0.0.2'
  s.platform          = Gem::Platform::RUBY
  s.authors           = [ 'Saku Ytti' ]
  s.email             = %w( saku@ytti.fi )
  s.homepage          = 'http://github.com/ytti/oxidized-script'
  s.summary           = 'cli + library for scripting network devices'
  s.description       = 'rancid clogin-like script to push configs to devices + library interface to do same'
  s.rubyforge_project = s.name
  s.files             = `git ls-files`.split("\n")
  s.executables       = %w( oxs )
  s.require_path      = 'lib'

  s.add_dependency 'oxidized'
  s.add_dependency 'slop'
end
