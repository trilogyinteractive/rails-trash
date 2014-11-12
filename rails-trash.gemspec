Gem::Specification.new do |s|
  s.name = 'rails-trash'
  s.version = '3.2.0'
  s.author = 'Jarred Trost'
  s.email = 'jtrost@trilogyinteractive.com'
  s.homepage = 'https://github.com/trilogyinteractive/rails-trash'
  s.summary = 'Trash'

  s.add_dependency('rails')

  s.add_development_dependency("minitest")
  s.add_development_dependency("factory_girl")
  s.add_development_dependency("sqlite3")

  s.files = Dir['lib/**/*']
  s.require_path = 'lib'
end