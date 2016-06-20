require "dropbox.rb"
require "applescript.rb"
require "yaml"

module Henchman

  class Core

    def self.run
      appleScript = Henchman::AppleScript.new
      puts 'henchman'

      while itunes_is_active? appleScript
        puts 'itunes open'
        config_file = File.expand_path('~/.henchman/config')
        begin
          config = YAML.load_file(config_file)
        rescue StandardError => err
          puts "Error opening config file. Try rerunning `henchman configure`"
          return
        end

        appleScript.setup config
        dbx = Henchman::DropboxAssistant.new config, appleScript
        dbx.connect

        artists = %x( ls #{config[:root]} ).split("\n")

        ignore = Hash.new
        ignore.default = 0

        puts "ignore list:"
        puts ignore.to_s

        info = Hash.new
        track_selected = appleScript.get_selection(info)

        unless !track_selected
          puts info.to_s

          if ignore[info[:artist]] < Time.now.to_i - config[:reprompt_timeout]
            ignore.delete(info[:artist])
            fetch = appleScript.fetch_prompt == "button returned:OK" ? true : false
            if fetch
              puts "fetching!"
              tracks = dbx.get_tracks(info[:artist], info[:album])
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
                dbx.download_single_track(info[:artist], info[:album], tracks[index])
                t = Thread.new{ dbx.download_album(info[:artist], info[:album], tracks, index) }
                puts "done!"
              end
            else
              puts "not fetching..."
              ignore[info[:artist]] = Time.now.to_i
            end
          end
        end
        sleep config[:poll_track]
      end
    end

    def self.itunes_is_active? appleScript
      appleScript.get_active_app == 'iTunes'
    end

  end

end
