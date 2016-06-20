require 'dropbox_sdk'
require 'yaml'
require 'json'

module Henchman

  class DropboxAssistant

    def initialize config, appleScript
      begin
        @config = config
        @appleScript = appleScript
        @client = DropboxClient.new(@config[:dropbox][:access_token])
        true
      rescue DropboxError => msg
        puts "Couldn't connect to Dropbox (#{msg}). \n"\
             "Run `henchman stop` then `henchman configure` \n"\
             "to configure Dropbox connection."
        false
      end
    end

    def get_tracks(artist, album)
      tracks = Array.new
      begin
        metadata = @client.metadata("#{@config[:dropbox][:root]}/#{artist}/#{album}")
        metadata['contents'].each { |track| tracks.push( (track['path'].split('/'))[-1] ) }
      rescue DropboxError => msg
        puts msg
      end
      tracks
    end

    def download_single_track(artist, album, track)
      puts "downloading #{track}"
      begin
        # download the file
        content = @client.get_file("#{@config[:dropbox][:root]}/#{artist}/#{album}/#{track}")

        # make sure we have the directory to put it in
        system 'mkdir', '-p', "#{@config[:root]}/#{artist}/#{album}"

        # save the file
        open(File.expand_path("#{@config[:root]}/#{artist}/#{album}/#{track}"), 'w') {|f| f.puts content }
        true
      rescue DropboxError => msg
        puts msg
        false
      end
    end

    # this downloads the whole album, except the skip track
    def download_album(artist, album, tracks, skip_track_index = nil)
      tracks.each_with_index { |track, index| download_single_track(artist, album, track) unless index == skip_track_index }
    end

    def search selection
      # search Dropbox for the file

      results = @client.search(@config[:dropbox][:root], selection[:track])

      # get rid of any results that are directories
      results.reject! { |result| result['is_dir'] }

      # if there were no results, raise err
      if results.empty?
        raise "Track not found in Dropbox: #{selection.inspect}"

      # if there's only one result, return it
      elsif results.length == 1
        results[0]['path']

      # if there are multiple results, score them based on artist + album
      else
        scores = Hash.new 0
        selection[:artist].downcase.split(/[^a-z0-9]/i).each do |token|
          results.each do |result|
            scores[result['path']] += 1 if result['path'].downcase.include? token
          end
        end

        # return the path that has the highest score
        return (scores.sort_by { |path, score| score })[-1][1]
      end
    end

  end

end
