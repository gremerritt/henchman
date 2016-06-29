require "henchman/version"
require "configure"
require "launchd_handler"
require "core"
require "clean"
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
        Henchman::Core.run
      end
    end

    command :clean do |c|
      c.syntax = 'henchman clean'
      c.description = 'Remove tracks from the file system that are old. '\
                      'Should not be ran manually.'
      c.action do |args, options|
        Henchman::Clean.run
      end
    end

  end
end
