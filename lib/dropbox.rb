require 'dropbox_sdk'
require 'yaml'

module Henchman
  
  class DropboxAssistant

    def initialize(config, appleScript)
    	@@config = config
      @@appleScript = appleScript
    end

    def connect
      begin
        @@client = DropboxClient.new(@@config[:dropbox][:access_token])
        return true
      rescue
        puts "Couldn't connect to Dropbox. Run `henchman stop` then `henchman configure` "\
             "to configure Dropbox connection."
        return false
      end
    end

    def get_tracks(artist, album)
      tracks = Array.new
      begin
        metadata = @@client.metadata("#{@@config[:dropbox][:root]}/#{artist}/#{album}")
        metadata['contents'].each { |track| tracks.push( (track['path'].split('/'))[-1] ) }
      rescue DropboxError => msg
        puts msg
      end
      return tracks
    end

    def download_single_track(artist, album, track)
      puts "downloading #{track}"
      begin
        # download the file
        content = @@client.get_file("#{@@config[:dropbox][:root]}/#{artist}/#{album}/#{track}")

        # make sure we have the directory to put it in
        system 'mkdir', '-p', "#{@@config[:root]}/#{artist}/#{album}"

        # save the file
        open(File.expand_path("#{@@config[:root]}/#{artist}/#{album}/#{track}"), 'w') {|f| f.puts content }
        return true
      rescue DropboxError => msg
        puts msg
        return false
      end
    end

    # this downloads the whole album, except the skip track
    def download_album(artist, album, tracks, skip_track_index = nil)
      tracks.each_with_index { |track, index| download_single_track(artist, album, track) unless index == skip_track_index }
    end

  end

end
