module Henchman

  class AppleScript

    def setup config
      @delimiter = config[:delimiter]
    end

    def get_active_app_script
      "tell application \"System Events\"\n"\
  	  "  set activeApp to name of first application process whose frontmost is true\n"\
  	  "  return activeApp\n"\
      "end tell"
    end

    def prompt_script
      "tell application \"iTunes\"\n"\
      "  display dialog \"Fetch?\"\n"\
      "end tell"
    end

    def update_track_location_script selection, local_file
      "tell application \"iTunes\"\n"\
      "  try\n"\
      "    set data_tracks to "\
      "      (every track whose artist is \"#{selection[:artist].gsub(/'/){ %q('"'"') }}\" and "\
      "                         album  is \"#{selection[:album].gsub(/'/){ %q('"'"') }}\"  and "\
      "                         name   is \"#{selection[:track].gsub(/'/){ %q('"'"') }}\")\n"\
      "    if (count of data_tracks) is 1 then\n"\
      "      set location of (item 1 of data_tracks) to "\
      "        (POSIX file \"#{local_file.gsub(/'/){ %q('"'"') }}\")\n"\
      "      return 1\n"\
      "    else\n"\
      "      return 0\n"\
      "    end if\n"\
      "  on error\n"\
      "    return 0\n"\
      "  end try\n"\
      "end tell"
    end

    def get_selection_script
      "tell application \"iTunes\"\n"\
      "  try\n"\
      "    if class of selection as string is \"file track\" then\n"\
      "      set data_artist to artist of selection as string\n"\
      "      set data_album to album of selection as string\n"\
      "      set data_title to name of selection as string\n"\
      "      set data_location to POSIX path of (location of selection as string)\n"\
      "      set str to data_artist & \"#{@delimiter}\" & "\
      "                 data_album  & \"#{@delimiter}\" & "\
      "                 data_title  & \"#{@delimiter}\" & "\
      "                 data_location\n"\
      "      return str\n"\
      "    end if\n"\
      "  on error\n"\
      "    return \"\"\n"\
      "  end try\n"\
      "end tell"
    end

    def get_album_tracks_script artist, album
      "tell application \"iTunes\"\n"\
      "  try\n"\
      "    set data_tracks to "\
      "        (every track whose artist is \"#{artist}\" "\
      "                        and album is \"#{album}\")\n"\
      "    set data_tracks_str to \"\"\n"\
      "    repeat with data_track in data_tracks\n"\
      "      set data_tracks_str to data_tracks_str & (name of data_track) as string\n"\
			"      if (name of (last item of data_tracks)) is not (name of data_track) then\n"\
			"        set data_tracks_str to data_tracks_str & \"#{@delimiter}\"\n"\
			"      end if\n"\
      "    end repeat\n"\
      "    return data_tracks_str\n"\
      "  on error\n"\
      "    return 0\n"\
      "  end try\n"\
      "end tell"
    end

    def applescript_command(script)
      "osascript -e '#{script}' 2> /dev/null"
    end

    def get_selection ret
      selection = %x( #{applescript_command(get_selection_script)} ).chomp
      info = selection.split(@delimiter)
      if info.empty?
        false
      elsif info[3] == "/missing value" || !File.exists?(info[3])
        ret[:artist]   = info[0]
        ret[:album]    = info[1]
        ret[:track]    = info[2]
        true
      else
        false
      end
    end

    def get_album_tracks_of selection
      artist = selection[:artist]
      album  = selection[:album]
      tracks = %x(#{applescript_command(get_album_tracks_script artist, album)}).chomp
      tracks = tracks.split(@delimiter)
      tracks.delete selection[:track]
      tracks
    end

    def fetch?
      (%x(#{applescript_command(prompt_script)}).chomp == "button returned:OK") ? true : false
    end

    def get_active_app
      %x(#{applescript_command(get_active_app_script)}).chomp
    end

    def set_track_location selection, local_file
      ret = %x(#{applescript_command(update_track_location_script selection, local_file)}).chomp
      if ret.empty? || ret == '0'
        puts "Could not update location of #{selection.values.join(':')} to #{local_file}"
        false
      else
        true
      end
    end

  end

end
