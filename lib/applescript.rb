require 'date'

module Henchman

  class AppleScript

    def setup config
      @delimiter       = config[:delimiter]
      @delimiter_major = config[:delimiter_major]
    end

    def get_active_app_script
      "tell application \"System Events\"\n"\
  	  "  set activeApp to name of first application process whose frontmost is true\n"\
  	  "  return activeApp\n"\
      "end tell"
    end

    def prompt_script buttons = []
      buttons = buttons.slice(0..1).map { |b| "Download #{b.gsub(/'/){ %q('"'"') }}" }
      "tell application \"iTunes\"\n"\
	    "  display dialog \"\""\
      "    buttons {"\
      "             \"Cancel\""\
      "             #{(buttons.length > 0) ? ",\"#{buttons.first}\"" : ''}"\
      "             #{(buttons.length > 1) ? ",\"#{buttons.last}\""  : ''}"\
      "            }"\
      "    with title \"Henchman 🏃\""\
      "    cancel button \"Cancel\""\
      "    default button \"#{(buttons.length > 0) ? buttons.last : 'Cancel'}\""\
      "    giving up after 60"\
      "    with icon note\n"\
      "end tell"
    end

    def update_track_location_script track_id, local_file
      "tell application \"iTunes\"\n"\
      "  try\n"\
      "    set data_tracks to (every track whose database ID is \"#{track_id}\")\n"\
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
      "      set data_id to database ID of selection as string\n"\
      "      set data_location to POSIX path of (location of selection as string)\n"\
      "      set str to data_artist & \"#{@delimiter}\" & "\
      "                 data_album  & \"#{@delimiter}\" & "\
      "                 data_title  & \"#{@delimiter}\" & "\
      "                 data_id  & \"#{@delimiter}\" & "\
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
      "    set album_tracks to "\
      "        (every track whose artist is \"#{artist.gsub(/'/){ %q('"'"') }}\" "\
      "                        and album is \"#{album.gsub(/'/){ %q('"'"') }}\")\n"\
      "    set str to \"\"\n"\
      "    repeat with album_track in album_tracks\n"\
      "      set data_location to location of album_track as string\n"\
      "      if data_location is equal to \"missing value\" then\n"\
      "        set data_artist to artist of album_track as string\n"\
      "        set data_album to album of album_track as string\n"\
      "        set data_title to name of album_track as string\n"\
      "        set data_id to database ID of album_track as string\n"\
      "        set str to str & data_artist & \"#{@delimiter}\" "\
      "                       & data_album  & \"#{@delimiter}\" "\
      "                       & data_title  & \"#{@delimiter}\" "\
      "                       & data_id     & \"#{@delimiter_major}\"\n"\
      "      end if\n"\
      "    end repeat\n"\
      "    return str\n"\
      "  on error\n"\
      "    return 0\n"\
      "  end try\n"\
      "end tell"
    end

    def get_playlist_script
      "tell application \"iTunes\"\n"\
      "	 try\n"\
    	"    set selected_playlist to (get view of front window)\n"\
      "    set playlist_name to name of selected_playlist as string\n"\
      "    set playlist_special to special kind of selected_playlist as string\n"\
      "    set str to playlist_name & \"#{@delimiter}\" & playlist_special\n"\
      "    return str\n"\
      "	 on error\n"\
      "    return 0\n"\
      "  end try\n"\
      "end tell"\
    end

    def progress
      "set progress description to \"A simple progress indicator\"\n"\
      "set progress additional description to \"Preparing…\"\n"\
      "set progress total steps to -1\n"\
      "\n"\
      "delay 5\n"\
      "\n"\
      "set progress total steps to 100\n"\
      "repeat with i from 1 to 100\n"\
      "  try\n"\
      "    set progress additional description to \"I am on step \" & i\n"\
      "    set progress completed steps to i\n"\
      "    delay 0.2\n"\
      "  on error thisErr\n"\
      "    display alert thisErr\n"\
      "    exit repeat\n"\
      "  end try\n"\
      "end repeat"
    end

    def get_playlist_tracks_script playlist, skip = [], size = 5
      "property counter : 0\n"\
      "tell application \"iTunes\"\n"\
      "  try\n"\
      "    set playlist_tracks to every track in playlist \"#{playlist.gsub(/'/){ %q('"'"') }}\"\n"\
      "    set str to \"\"\n"\
      "    repeat with playlist_track in playlist_tracks\n"\
      "      set data_location to location of playlist_track as string\n"\
      "      set data_id to database ID of playlist_track as string\n"\
      "      if data_location is equal to \"missing value\" "\
      "      and data_id is not in [#{skip.map{|e| "\"#{e}\""}.join(',')}] then\n"\
      "        set data_artist to artist of playlist_track as string\n"\
      "        set data_album to album of playlist_track as string\n"\
      "        set data_title to name of playlist_track as string\n"\
      "        set str to str & data_artist & \"#{@delimiter}\""\
      "                       & data_album  & \"#{@delimiter}\""\
      "                       & data_title  & \"#{@delimiter}\""\
      "                       & data_id     & \"#{@delimiter_major}\"\n"\
      "        set counter to counter + 1\n"\
      "        if counter is equal to #{size} then exit repeat\n"\
      "      end if\n"\
      "    end repeat\n"\
      "    return str\n"\
      "  on error\n"\
      "    return 0\n"\
      "  end try\n"\
      "end tell"
    end

    def get_tracks_with_location_script
      "tell application \"iTunes\"\n"\
      "  try\n"\
      "    set all_tracks to every track in playlist \"Music\"\n"\
		  "    set str to \"\"\n"\
		  "    repeat with cur_track in all_tracks\n"\
			"      set data_location to location of cur_track as string\n"\
			"      if data_location is not equal to \"missing value\" then\n"\
			"        set data_id to database ID of cur_track as string\n"\
			"        set data_date to played date of cur_track\n"\
			"        set str to str & data_id   & \"#{@delimiter}\""\
      "                       & data_date & \"#{@delimiter}\""\
      " & (POSIX path of data_location as string) & \"#{@delimiter_major}\"\n"\
			"      end if\n"\
		  "    end repeat\n"\
		  "    return str\n"\
      "  on error\n"\
		  "    return 0\n"\
	    "  end try\n"\
      "end tell\n"\
    end

    def applescript_command(script)
      "osascript -e '#{script}' 2> /dev/null"
    end

    def get_selection
      selection = %x( #{applescript_command(get_selection_script)} ).chomp
      info = selection.split @delimiter
      track = Hash.new
      if !info.empty?
        track[:artist] = info[0]
        track[:album]  = info[1]
        track[:track]  = info[2]
        track[:id]     = info[3]
        track[:path]   = info[4]
      end
      track
    end

    def get_tracks_with_location
      tracks = Array.new
      tmp_tracks = %x(#{applescript_command(get_tracks_with_location_script)}).chomp
      tmp_tracks = tmp_tracks.split @delimiter_major
      tmp_tracks.each do |track|
        next if track.empty?
        tmp_track = track.split @delimiter
        tracks.push( {:id   => tmp_track[0],
                      :date => (tmp_track[1] != 'missing value') ? DateTime.parse(tmp_track[1]) : DateTime.new,
                      :path => tmp_track[2]} )
      end
      tracks
    end

    def get_playlist
      playlist = %x(#{applescript_command(get_playlist_script)}).chomp
      playlist = playlist.split @delimiter
      if playlist[1] != 'none'
        false
      else
        playlist[0]
      end
    end

    def get_playlist_tracks playlist, skip = []
      tracks = Array.new
      tmp_tracks = %x(#{applescript_command(get_playlist_tracks_script playlist, skip)}).chomp
      tmp_tracks = tmp_tracks.force_encoding("UTF-8").split @delimiter_major
      tmp_tracks.each do |track|
        next if track.empty?
        tmp_track = track.split @delimiter
        tracks.push( {:artist => tmp_track[0],
                      :album  => tmp_track[1],
                      :track  => tmp_track[2],
                      :id     => tmp_track[3]} )
      end
      tracks
    end

    def get_album_tracks_of selection
      artist = selection[:artist]
      album  = selection[:album]
      tracks = Array.new
      tmp_tracks = %x(#{applescript_command(get_album_tracks_script artist, album)}).chomp
      tmp_tracks = tmp_tracks.split @delimiter_major
      tmp_tracks.each do |track|
        next if track.empty?
        tmp_track = track.split @delimiter
        next if tmp_track[3] == selection[:id]
        tracks.push( {:artist => tmp_track[0],
                      :album  => tmp_track[1],
                      :track  => tmp_track[2],
                      :id     => tmp_track[3]} )
      end
      tracks
    end

    def fetch? buttons = []
      resp = %x(#{applescript_command(prompt_script buttons)}).chomp
      resp.split(',').first.split(':').last.split('Download ').last rescue ''
    end

    def get_active_app
      %x(#{applescript_command(get_active_app_script)}).chomp
    end

    def set_track_location selection, local_file
      puts "#{DateTime.now.strftime('%m-%d-%Y %H:%M:%S')}|"\
           "Updating location of #{selection.reject{|k,v| k == :path || k == :id}.values.join(':')} to #{local_file}"

      ret = %x(#{applescript_command(update_track_location_script selection[:id], local_file)}).chomp
      if ret.empty? || ret == '0'
        false
      else
        true
      end
    end

  end

end
