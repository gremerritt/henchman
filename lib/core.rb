require "dropbox.rb"
require "applescript.rb"
requier "yaml"

module Henchman

  class Core

    def self.run
      config_file = File.expand_path('~/.henchman/config')
      begin
        config = YAML.load_file(config_file)
      rescue StandardError => err
        puts "Error opening config file. Try rerunning `henchman configure`"
        return
      end

      delim = "|~|"
      delay_minutes = 5
      delay = delay_minutes * 60
      dbx_root = '/Music'
      machine_root = File.expand_path('~/Desktop/Music')

      appleScript = Henchman::AppleScript.new(config)
      dbx = Henchman::DropboxAssistant.new(config, appleScript)
      dbx.connect

      artists = %x( ls #{machine_root} ).split("\n")

      ignore = Hash.new

      while itunes_is_active? appleScript
        puts "ignore list:"
        puts ignore.to_s

        info = Hash.new
        track_selected = appleScript.get_selection(info)

        unless !track_selected
          puts info.to_s

          if (!ignore.include? info[:artist] ||
               ignore[info[:artist]] < Time.now.to_i - config[:reprompt_timeout]) &&
               !artists.include? info[:artist]
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
