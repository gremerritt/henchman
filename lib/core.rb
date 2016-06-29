require "dropbox.rb"
require "applescript.rb"
require "yaml"

module Henchman

  class Core

    def self.run
      @appleScript = Henchman::AppleScript.new

      begin
        cache_file = File.expand_path("~/.henchman/cache")
        @cache = YAML.load_file(cache_file)
        raise "Incorrectly formatted cache" if !(@cache.include? :ignore)

        @cache[:ignore].each_value { |val| val.default = 0 }
      rescue StandardError => err
        puts "Error opening cache file (#{err})"
        @cache = Henchman::Templates.cache
      end

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

        track = @appleScript.get_selection

        if track_selected? track
          if (missing_track_selected? track) && !(ignore? :artist, track[:artist])
            update_cache = true
            update_ignore :artist, track[:artist]
            if @appleScript.fetch? "#{track[:album]} by #{track[:artist]}"
              begin
                # first download the selected track
                dropbox_path   = @dropbox.search_for track
                file_save_path = @dropbox.download track, dropbox_path
                tag track

                # if we downloaded it, update the location of the track in iTunes
                unless !file_save_path
                  updated = @appleScript.set_track_location track, file_save_path
                  # if the update failed, cleanup that directory and don't bother
                  # doing the rest of the album
                  if !updated
                    cleanup file_save_path, track
                    next
                  end

                  # now that we've gotten the selected track, spawn off another process
                  # to download the rest of the tracks on the album - spatial locality FTW
                  album_tracks = @appleScript.get_album_tracks_of track
                  threads << Thread.new{ download_tracks album_tracks }
                end
              rescue StandardError => err
                puts err
                next
              end
            end
          end
        else
          playlist = @appleScript.get_playlist
          if playlist
            playlist_tracks = @appleScript.get_playlist_tracks playlist
            if (!playlist_tracks.empty?) && !(ignore? :playlist, playlist)
              update_cache = true
              update_ignore :playlist, playlist
              if @appleScript.fetch? playlist
                threads << Thread.new{ download_tracks playlist_tracks }
              end
            end
          end
        end
        sleep @config[:poll_track]
      end

      threads.each { |thr| thr.join }
      File.open(cache_file, "w") { |f| f.write( @cache.to_yaml ) } if update_cache
    end

    def self.update_ignore type, identifier
      return false if !(valid_ignore_type? type)
      @cache[:ignore][type][identifier] = Time.now.to_i
    end

    def self.ignore? type, identifier
      return false if !(valid_ignore_type? type)
      @cache[:ignore][type][identifier] >= (Time.now.to_i - @config[:reprompt_timeout])
    end

    def self.valid_ignore_type? type
      if !(Henchman::Templates.cache[:ignore].keys.include? type)
        puts "Invalid type '#{type}' for ignore cache check"
        false
      else
        true
      end
    end

    def self.tag track
      @cache[:history][track[:id].to_i] = Time.now.to_i
    end

    def self.track_selected? track
      !track.empty?
    end

    def self.missing_track_selected? track
      track[:path] == '/missing value'
    end

    def self.itunes_is_active?
      @appleScript.get_active_app == 'iTunes'
    end

    def self.download_tracks album_tracks
      album_tracks.each { |album_track| download_and_update album_track }
    end

    def self.download_and_update track
      begin
        # first download the selected track
        dropbox_path   = @dropbox.search_for track
        file_save_path = @dropbox.download track, dropbox_path
        tag track

        # if we downloaded it, update the location of the track in iTunes
        unless !file_save_path
          updated = @appleScript.set_track_location track, file_save_path

          # if the update failed, remove that file
          cleanup file_save_path, track if !updated
        end
      rescue StandardError => err
        puts err
      end
    end

    def self.cleanup file_save_path, track
      File.delete file_save_path
      @cache[:history].delete track[:id].to_i
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
