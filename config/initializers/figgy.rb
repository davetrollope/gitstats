AppConfig = Figgy.build do |config|
  config.root = Rails.root.join('etc')

  # config.foo is read from etc/foo.yml
  config.define_overlay :default, nil

  # config.foo is then updated with values from etc/production/foo.yml
  config.define_overlay(:environment) { Rails.env }

  # Maybe you need to load XML files?
  config.define_handler 'xml' do |contents|
    Hash.from_xml(contents)
  end
end
