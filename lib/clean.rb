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

      cutoff = DateTime.now - 1

      tracks = @appleScript.get_tracks_with_location
      tracks.each do |track|
        cache_time = @cache.get_time_last_downloaded track
        if track[:date] < cutoff && cache_time < cutoff
          cleanup track
        end
      end

      @cache.flush

    end

    def self.cleanup track
      filepath = track[:path]
      File.delete filepath
      @cache.delete track
      puts "Deleted #{filepath}"

      while File.dirname(filepath) != @config[:root]
        filepath = File.dirname(filepath)
        begin
          Dir.rmdir(filepath)
          puts "Deleted #{filepath}"
        rescue SystemCallError => msg
          break
        end
      end
    end

  end

end
