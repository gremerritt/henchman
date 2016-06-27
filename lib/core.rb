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

      threads = []
      update_cache = false

      while itunes_is_active?
        begin
          @config = YAML.load_file(File.expand_path('~/.henchman/config'))
        rescue StandardError => err
          puts "Error opening config file. Try rerunning `henchman configure`"
          return
        end

        @appleScript.setup @config
        begin
          @dropbox = Henchman::DropboxAssistant.new @config
        rescue
          puts "Error connecting to Dropbox. Try rerunning `henchman configure`"
          return
        end

        selection = Hash.new
        track_selected = @appleScript.get_selection selection

        if track_selected && @ignore[selection[:artist]] < (Time.now.to_i - @config[:reprompt_timeout])
          update_cache = true
          @ignore.delete selection[:artist]
          if @appleScript.fetch?
            puts "searching"
            begin
              # first download the selected track
              dropbox_path   = @dropbox.search_for selection
              file_save_path = @dropbox.download selection, dropbox_path

              # if we downloaded it, update the location of the track in iTunes
              unless !file_save_path
                updated = @appleScript.set_track_location selection, file_save_path
                # if the update failed, cleanup that directory and don't bother
                # doing the rest of the album
                if !updated
                  cleanup file_save_path
                  next
                end

                # now that we've gotten the selected track, spawn off another process
                # to download the rest of the tracks on the album - spatial locality FTW
                album_tracks = @appleScript.get_album_tracks_of selection
                threads << Thread.new{ download_album_tracks selection, album_tracks }
              end
            rescue StandardError => err
              puts err
              next
            end
          else
            @ignore[selection[:artist]] = Time.now.to_i
          end
        end
        sleep @config[:poll_track]
      end

      threads.each { |thr| thr.join }
      File.open(cache_file, "w") { |f| f.write( @ignore.to_yaml ) } if update_cache
    end

    def self.itunes_is_active?
      @appleScript.get_active_app == 'iTunes'
    end

    def self.download_album_tracks selection, album_tracks
      album_tracks.each do |album_track|
        selection[:track] = album_track[:track]
        selection[:id]    = album_track[:id]
        begin
          # first download the selected track
          dropbox_path   = @dropbox.search_for selection
          file_save_path = @dropbox.download selection, dropbox_path

          # if we downloaded it, update the location of the track in iTunes
          unless !file_save_path
            updated = @appleScript.set_track_location selection, file_save_path
            # if the update failed, remove that file
            if !updated
              cleanup file_save_path
              next
            end
          end
        rescue StandardError => err
          puts err
          next
        end
      end
    end

    def self.cleanup file_save_path
      File.delete file_save_path
      while File.dirname(file_save_path) != @config[:root]
        file_save_path = File.dirname(file_save_path)
        begin
          Dir.rmdir(file_save_path)
        rescue SystemCallError => msg
          break
        end
      end
    end

  end

end
