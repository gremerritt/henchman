module Henchman

  class AppleScript

    def initialize
      @@script_get_active_app = "tell application \"System Events\"\n
  	                               set activeApp to name of first application process whose frontmost is true\n
  	                               return activeApp\n
                                 end tell"
    end

    def setup config
      @@delimiter = config[:delimiter]
      @@script_get_selection = "tell application \"iTunes\"\n
                                  try\n
                                    if class of selection as string is \"file track\" then\n
                                      set data_artist to artist of selection as string\n
                                      set data_album to album of selection as string\n
                                      set data_title to name of selection as string\n
                                      set str to data_artist & \"#{@@delimiter}\" & data_album & \"#{@@delimiter}\" & data_title\n
                                      --display dialog location of selection as string\n
                                      return str\n
                                    end if\n
                                  on error\n
                                    --do nothing\n
                                  end try\n
                                end tell"
      @@script_prompt = "tell application \"iTunes\"\n
                           display dialog \"Fetch?\"\n
                         end tell"
      @@update_track_location_temp = "tell application \"iTunes\"\n
                                        try\n
                                          set data_tracks to (every track whose artist is \"{ITUNES_ARTIST}\" and album is \"{ITUNES_ALBUM}\" and name is \"{ITUNES_NAME}\")\n
                                          if (count of data_tracks) is 1 then\n
                                            set location of (item 1 of data_tracks) to \"Macintosh HD#{config[:root].gsub("/", ":")}:{LOCAL_ARTIST}:{LOCAL_ALBUM}:{LOCAL_NAME}\"\n
                                            return 1\n
                                          else\n
                                            return 0\n
                                          end if\n
                                        on error\n
                                          return 0\n
                                        end try\n
                                      end tell"
    end

    def applescript_command(script)
      "osascript -e '#{script}' 2> /dev/null"
    end

    def get_selection ret
      selection = %x( #{applescript_command(@@script_get_selection)} ).chomp
      info = selection.split(@@delimiter)
      if info.length == 3
        ret[:artist] = info[0]
        ret[:album]  = info[1]
        ret[:track]  = info[2]
        true
      else
        false
      end
    end

    def fetch_prompt
      %x( #{applescript_command(@@script_prompt)} ).chomp
    end

    def get_active_app
      %x( #{applescript_command(@@script_get_active_app)} ).chomp
    end

    def set_track_location
      update_track_location = @@update_track_location_temp.gsub("{ITUNES_ARTIST}", "i_art")
                                                          .gsub("{ITUNES_ALBUM}", "i_alb")
                                                          .gsub("{ITUNES_NAME}", "i_name")
                                                          .gsub("{LOCAL_ARTIST}", "local_art")
                                                          .gsub("{LOCAL_ALBUM}", "local_alb")
                                                          .gsub("{LOCAL_NAME}", "local_name")
      puts update_track_location
    end

  end

end
