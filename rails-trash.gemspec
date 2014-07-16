Gem::Specification.new do |s|
  s.name = 'rails-trash'
  s.version = '3.2.0'
  s.author = 'Francesc Esplugas'
  s.email = 'contact@francescesplugas.com'
  s.homepage = 'https://github.com/fesplugas/rails-trash'
  s.summary = 'Trash'

  s.add_dependency('rails')

  s.add_development_dependency("minitest")
  s.add_development_dependency("factory_girl")
  s.add_development_dependency("sqlite3")

  s.files = Dir['lib/**/*']
  s.require_path = 'lib'
end
