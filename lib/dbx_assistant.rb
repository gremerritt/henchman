require 'dropbox'
require 'yaml'
require 'json'

module Henchman

  class DropboxAssistant

    def initialize config, debug
      begin
        @search_limit = 500
        @debug  = debug
        @config = config
        @client = Dropbox::Client.new @config[:dropbox][:access_token]

        # stop words from http://nlp.stanford.edu/IR-book/html/htmledition/dropping-common-terms-stop-words-1.html
        @stop_words = ['a', 'an', 'and', 'are', 'as', 'at', 'be', 'by', 'for', 'from',
                       'has', 'he', 'in', 'is', 'it', 'its', 'of', 'on', 'that', 'the',
                       'to', 'was', 'were', 'will', 'with']
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
        content, body = @client.download dropbox_path

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

    def search value, filter = nil, dir = @config[:dropbox][:root]
      puts "Searching for #{value} in #{dir}, filtering by <#{filter}>" if @debug
      begin
        results = @client.search dir, value, 0, @search_limit
        puts JSON.pretty_generate results
        puts "#{results.length} total results found" if @debug
        if filter == :dir
          results.reject! { |result| !result['is_dir'] }
        elsif filter == :file
          results.reject! { |result| result['is_dir'] || !(@config[:file_extensions].include?(File.extname(result['path'])[1..-1])) }
        end
        puts "Returning #{results.length} results for `search` (after filtering)" if @debug
        return results
      rescue DropboxError => msg
        raise "Error accessing Dropbox Search API|#{value}|#{dir}|#{msg}"
      end
    end

    def get_results track, artist
      puts "`get_results` for #{track} by #{artist}" if @debug
      # Search Dropbox for the file
      # We're only not filtering to get files because we want to check if we get 1000 results
      # (i.e. a maxed out playload) back. This is because the filtering happens in OUR client,
      # not in the Dropbox search. We're doing a simple search on only track name because we
      # want to minimize the number of network calls, and USUALLY this is good enough
      results = search track

      # If we get 1000 results back, it means we probably have a REALLY simple song title
      # and we're not assured to have the target song in our payload, since we maxed it
      # out. So, we'll do another search call on the artist
      if results.length == @search_limit
        puts "Maximum (#{@search_limit}) results returned" if @debug
        results.clear
        album_dirs = search artist, :dir
        album_dirs.each do |album|
          tmp_rslts = search track, :file, album['path']
          results.push(*tmp_rslts)
        end
      else    # Otherwise, filter off all the directories and things without the right extensions
        puts "Filtering out directories and incorrect file extensions" if @debug
        results.reject! { |result| result['is_dir'] || !(@config[:file_extensions].include?(File.extname(result['path'])[1..-1])) }
      end
      puts "Returning #{results.length} results from `get_results`" if @debug
      return results
    end

    def search_for selection
      puts "#{DateTime.now.strftime('%m-%d-%Y %H:%M:%S')}|"\
           "Searching for #{selection.reject{|k,v| k == :path || k == :id}.values.join(':')}"

      results = get_results selection[:track], selection[:artist]

      # if we still don't have any results, try dropping any brackets and paranthesis
      if results.empty? && (selection[:track].match(%r( *\[.*\] *)) || selection[:track].match(%r( *\(.*\) *)))
        puts "No results. Trying without brackets or parenthesis" if @debug
        track = selection[:track].gsub(%r( *\[.*\] *), " ").gsub(%r( *\(.*\) *), " ")
        results = get_results selection[:track], selection[:artist]
      end

      # if there were no results, raise err
      if results.empty?
        raise "Track not found in Dropbox: #{selection.reject{|k,v| k == :id}.values.join(':')}"
      else
        scores       = Hash.new 0
        tokens       = Array.new
        track_tokens = Array.new
        [:artist, :album].each do |identifier|
          tokens |= selection[identifier].downcase
                                         .gsub(%r( +), " ")
                                         .gsub(%r(-+), "-")
                                         .strip
                                         .split(/[\s-]/)
                                         .delete_if{ |t| @stop_words.include? t }
        end
        @config[:file_extensions].each do |extension|
          track_tokens |= selection[:track].downcase
                                           .gsub(%r( +), " ")
                                           .gsub(%r(-+), "-")
                                           .strip
                                           .split(/[\s-]/)
                                           .map { |t| "#{t}.#{extension}" }
        end

        if @debug
          puts ":artist and :album tokens: #{tokens.inspect}"
          puts ":track tokens: #{track_tokens.inspect}"
        end

        results.each do |result|
          dir = "#{File.dirname(result['path']).downcase}/"
          basename = " #{File.basename(result['path']).downcase}"
          tokens.each do |token|
            if dir =~ %r(.*[\s\/-]#{token}[\s\/-].*)
              puts "Token #{token} found in #{dir}" if @debug
              if results.length == 1
                return result['path']
              else
                scores[result['path']] += 1
              end
            end
          end
          track_tokens.each do |token|
            if basename =~ %r([.]*[\s-]+#{token})
              puts "Token #{token} found in #{basename}" if @debug
              scores[result['path']] += 1
            end
          end
        end

        # if the we only had one track and we're here, that means the path didn't contain
        # any of the album or artist tokens, so we'll say we couldn't find it
        if results.length == 1
          raise "Track not found in Dropbox: #{selection.reject{|k,v| k == :id}.values.join(':')}"
        end

        # return the path that has the highest score
        scores = scores.sort_by { |path, score| score }
        if @debug
          scores.each { |score| puts score.join ': ' }
        end
        scores[-1][0]
      end
    end

  end

end
