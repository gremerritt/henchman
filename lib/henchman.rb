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
        Henchman::LaunchdHandler.start args
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
        Henchman::Core.run args
      end
    end

    command :clean do |c|
      c.syntax = 'henchman clean [options]'
      c.description = 'Remove tracks from the file system that are old. '\
                      'Should not be ran manually.'
      c.option '--played_date \'true\'/\'false\'', String, 'Delete tracks based only on last played date'
      c.action do |args, options|
        options.default :played_date => 'false'
        Henchman::Clean.run options.played_date
      end
    end

    command :extensions do |c|
      c.syntax = 'henchman extensions'
      c.description = 'Collect file extensions'
      c.action do |args, options|
        Henchman.collect_exts
      end
    end

    command :log do |c|
      c.syntax = 'henchman log [options]'
      c.description = 'Tails the henchman stdout log'
      c.option '--n <number>', Integer, 'Number of lines to tail'
      c.action do |args, options|
        options.default :n => 10
        puts `tail -n #{options.n} #{File.expand_path('~/.henchman/stdout.log')}`
      end
    end

    command :clear do |c|
      c.syntax = 'henchman clear <artist/playlist> <title>'
      c.description = 'Clears the the artist or playlist from the cache'
      c.action do |args, options|
        @cache = Henchman::Cache.new
        @cache.clear args[0].to_sym, args[1..-1].join(' ')
      end
    end
  end
end
