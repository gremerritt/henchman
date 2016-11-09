require "applescript"
require "cache"
require "date"

module Henchman

  class Clean

    def self.run played_date
      puts "#{DateTime.now.strftime('%m-%d-%Y %H:%M:%S')}|"\
           "Cleanup Starting"

      played_date = (played_date == 'true') ? true : false

      @appleScript = Henchman::AppleScript.new
      @cache = Henchman::Cache.new
      begin
        @config = YAML.load_file(File.expand_path('~/.henchman/config'))
        @cache.config @config
        @appleScript.setup @config
      rescue StandardError => err
        puts "#{DateTime.now.strftime('%m-%d-%Y %H:%M:%S')}|"\
             "Error opening config file. Try rerunning `henchman configure`"
        return
      end

      cutoff = DateTime.now - 1

      tracks = @appleScript.get_tracks_with_location
      tracks.each do |track|
        cache_time = @cache.get_time_last_downloaded track
        puts "cache_time: #{cache_time} (#{cache_time.class})"
        if track[:date] < cutoff && ((cache_time < cutoff) || played_date)
          cleanup track
        end
      end

      @cache.flush

      puts "#{DateTime.now.strftime('%m-%d-%Y %H:%M:%S')}|"\
           "Cleanup Finished"

    end

    def self.cleanup track
      filepath = track[:path]
      begin
        File.delete filepath
        @cache.delete track
        puts "#{DateTime.now.strftime('%m-%d-%Y %H:%M:%S')}|"\
             "Deleted #{filepath}"

        while File.dirname(filepath) != @config[:root]
          filepath = File.dirname(filepath)
          Dir.rmdir(filepath)
          puts "#{DateTime.now.strftime('%m-%d-%Y %H:%M:%S')}|"\
               "Deleted #{filepath}"
        end
      rescue SystemCallError => msg
        # do nothing
      end
    end

  end

end
