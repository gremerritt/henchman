require "henchman/version"
require "templates"
require "commander/import"
require "yaml"

module Henchman
  def Henchman.run
    program :name, 'Henchman'
    program :version, Henchman::VERSION
    program :description, 'Cloud music syncing for iTunes on OS X'

    command :start do |c|
      c.syntax = 'henchman start'
      c.description = 'Starts the henchman daemon'
      c.action do |args, options|
        if !File.exists?(File.expand_path('~/.henchman'))
          say 'Configuration file is missing.'
          say 'Run `henchman configure` to setup the henchman client.'
          next
        end
        say 'HERE'
      end
    end

    command :configure do |c|
      c.syntax = 'henchman configure'
      c.description = 'Configures the henchman client'
      c.action do |args, options|
        config_file = File.expand_path('~/.henchman')
        if !File.exists?(config_file)
          config = Henchman::Templates.config
        else
          config = YAML.load_file(config_file)
        end
        puts config
      end
    end

  end
end
