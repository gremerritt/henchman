require "templates"
require "yaml"

module Henchman
  def self.configure
    config_file = File.expand_path('~/.henchman')
    if !File.exists?(config_file)
      config = Henchman::Templates.config
    else
      config = YAML.load_file(config_file)
    end

    if config[:dropbox][:username].empty? ||
       config[:dropbox][:password].empty? ||
       agree("Update Dropbox credentials?")
      get_dropbox_credentials(config)
    end

    File.open(config_file, "w") { |f| f.write( config.to_yaml ) }
  end

  def get_dropbox_credentials(config)
    puts 'getting creds'
  end
end
