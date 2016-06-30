require "applescript"
require "cache"
require "date"

module Henchman

  class Clean

    def self.run

      puts "Cleanup ran at #{DateTime.now.strftime('%m-%d-%Y %k:%M:%S%p')}"

      @appleScript = Henchman::AppleScript.new
      @cache = Henchman::Cache.new
      begin
        @config = YAML.load_file(File.expand_path('~/.henchman/config'))
        @cache.config @config
        @appleScript.setup @config
      rescue StandardError => err
        puts "Error opening config file. Try rerunning `henchman configure`"
        return
      end

      puts JSON.pretty_generate @appleScript.get_tracks_with_location

    end

  end

end
