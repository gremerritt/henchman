require "dropbox.rb"
require "applescript.rb"
require "yaml"

module Henchman

  class Core

    def self.run
      @appleScript = Henchman::AppleScript.new

      begin
        cache_file = File.expand_path("~/.henchman/cache")
        @ignore = YAML.load_file(cache_file)
      rescue StandardError => err
        puts "Error opening cache file (#{err})"
        @ignore = Hash.new
      end
      @ignore.default = 0
      update_cache = false

      while itunes_is_active?
        begin
          config = YAML.load_file(File.expand_path('~/.henchman/config'))
        rescue StandardError => err
          puts "Error opening config file. Try rerunning `henchman configure`"
          return
        end

        @appleScript.setup config
        begin
          @dropbox = Henchman::DropboxAssistant.new config, @appleScript
        rescue
          puts "Error connecting to Dropbox. Try rerunning `henchman configure`"
          return
        end

        selection = Hash.new
        track_selected = @appleScript.get_selection selection

        if track_selected && @ignore[selection[:artist]] < (Time.now.to_i - config[:reprompt_timeout])
          update_cache = true
          @ignore.delete selection[:artist]
          if @appleScript.fetch?
            puts "searching"
            begin
              puts @dropbox.search selection
              puts @appleScript.get_album_tracks selection
            rescue StandardError => err
              puts err
              next
            end
            next

            tracks = @dropbox.get_tracks(selection[:artist], selection[:album])
            index = -1
            tracks.each_with_index do |dbx_track, dbx_track_index|
              if dbx_track.downcase.include? info[:track].downcase
                puts "Found ""#{dbx_track}"""
                index = dbx_track_index
                break
              end
            end

            if index >= 0
              puts "downloading track..."
              @dropbox.download_single_track(selection[:artist], selection[:album], tracks[index])
              t = Thread.new{ @dropbox.download_album(selection[:artist], selection[:album], tracks, index) }
              puts "done!"
            end
          else
            @ignore[selection[:artist]] = Time.now.to_i
          end
        end
        sleep config[:poll_track]
      end

      File.open(cache_file, "w") { |f| f.write( @ignore.to_yaml ) } if update_cache
    end

    def self.itunes_is_active?
      @appleScript.get_active_app == 'iTunes'
    end

  end

end
