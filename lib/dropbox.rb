require 'dropbox_sdk'
require 'yaml'
require 'json'

module Henchman

  class DropboxAssistant

    def initialize config
      begin
        @config = config
        @client = DropboxClient.new(@config[:dropbox][:access_token])
        true
      rescue DropboxError => msg
        puts "#{DateTime.now.strftime('%m-%d-%Y %H:%M:%S')}|"\
             "Couldn't connect to Dropbox (#{msg}). "\
             "Run `henchman stop` then `henchman configure` "\
             "to configure Dropbox connection."
        false
      end
    end

    def download selection, dropbox_path
      puts "#{DateTime.now.strftime('%m-%d-%Y %H:%M:%S')}|"\
           "Downloading #{selection.reject{|k,v| k == :path || k == :id}.values.join(':')}"
      begin
        # download the file
        content = @client.get_file(dropbox_path)

        # make sure we have the directory to put it in
        trgt_dir = File.join @config[:root], selection[:artist], selection[:album]
        system 'mkdir', '-p', trgt_dir

        # save the file
        file_save_path = File.join trgt_dir, File.basename(dropbox_path)
        open(file_save_path, 'w') {|f| f.puts content }
        file_save_path
      rescue DropboxError => msg
        puts "#{DateTime.now.strftime('%m-%d-%Y %H:%M:%S')}|"\
             "Error downloading Dropbox file #{dropbox_path}: #{msg}"
        false
      rescue StandardError => msg
        puts "#{DateTime.now.strftime('%m-%d-%Y %H:%M:%S')}|"\
             "Error saving Dropbox file #{dropbox_path} to #{trgt_dir}: #{msg}"
        false
      end
    end

    def search_for selection
      puts "#{DateTime.now.strftime('%m-%d-%Y %H:%M:%S')}|"\
           "Searching for #{selection.reject{|k,v| k == :path || k == :id}.values.join(':')}"

      # search Dropbox for the file
      begin
        results = @client.search(@config[:dropbox][:root], selection[:track])
      rescue DropboxError => msg
        raise "Error accessing Dropbox Search API on #{selection.reject{|k,v| k == :path || k == :id}.values.join(':')}: #{msg}"
      end

      # get rid of any results that are directories
      results.reject! { |result| result['is_dir'] }

      # if we still don't have any results, try dropping any brackets and paranthesis
      if results.empty? && (selection[:track].match(%r( *\[.*\] *)) || selection[:track].match(%r( *\(.*\) *)))
        track = selection[:track].gsub(%r( *\[.*\] *), " ").gsub(%r( *\(.*\) *), " ")
        results = @client.search(@config[:dropbox][:root], track)
        results.reject! { |result| result['is_dir'] }
      end

      # if there were no results, raise err
      if results.empty?
        raise "Track not found in Dropbox: #{selection.inspect}"

      # if there's only one result, return it
      elsif results.length == 1
        results[0]['path']

      # if there are multiple results, score them based on artist + album
      else
        scores = Hash.new 0
        results.each do |result|
          [:artist, :album].each do |identifier|
            tokens = selection[identifier].downcase
                                          .gsub(%r( +), " ")
                                          .gsub(%r(-+), "-")
                                          .strip
                                          .split(/[\s-]/)
            tokens.each do |token|
              scores[result['path']] += 1 if result['path'].downcase.include? token
            end
          end
        end

        # return the path that has the highest score
        (scores.sort_by { |path, score| score })[-1][0]
      end
    end

  end

end
