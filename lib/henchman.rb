require "henchman/version"
require "configure"
require "launchd_handler"
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
        Henchman::LaunchdHandler.start
      end
    end

    command :stop do |c|
      c.syntax = 'henchman stop'
      c.description = 'Stops the henchman daemon'
      c.action do |args, options|
        Henchman::LaunchdHandler.stop
      end
    end

    command :configure do |c|
      c.syntax = 'henchman configure'
      c.description = 'Configures the henchman client'
      c.action do |args, options|
        Henchman.configure
      end
    end

    command :run do |c|
      c.syntax = 'henchman run'
      c.description = 'Main interface into henchman. Should not be ran manually.'
      c.action do |args, options|
        puts "Hello World!"
      end
    end

  end
end
