require "dropbox.rb"
require "applescript.rb"
require "yaml"

module Henchman

  class Core

    def self.run
      @appleScript = Henchman::AppleScript.new

      while itunes_is_active?
        puts 'itunes open'
        config_file = File.expand_path('~/.henchman/config')
        begin
          config = YAML.load_file(config_file)
        rescue StandardError => err
          puts "Error opening config file. Try rerunning `henchman configure`"
          return
        end

        @appleScript.setup config
        begin
          @dropbox = Henchman::DropboxAssistant.new config, @appleScript
        rescue
          return
        end

        artists = %x( ls #{config[:root]} ).split("\n")

        ignore = Hash.new
        ignore.default = 0

        puts "ignore list:"
        puts ignore.to_s

        selection = Hash.new
        track_selected = @appleScript.get_selection selection

        if track_selected && ignore[selection[:artist]] < (Time.now.to_i - config[:reprompt_timeout])
          ignore.delete selection[:artist]
          if @appleScript.fetch?
            puts "fetching!"
            puts @dropbox.search selection
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
            puts "not fetching..."
            ignore[selection[:artist]] = Time.now.to_i
          end
        end
        sleep config[:poll_track]
      end
    end

    def self.itunes_is_active?
      @appleScript.get_active_app == 'iTunes'
    end

  end

end
