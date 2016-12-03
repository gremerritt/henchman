require "templates"
require "date"

module Henchman

  class Cache

    def initialize
      begin
        @cache_file = File.expand_path("~/.henchman/cache")
        @cache = YAML.load_file(@cache_file)
        raise "Incorrectly formatted cache" if !(@cache.include? :ignore)

        @cache[:ignore].each_value { |val| val.default = 0 }
      rescue StandardError => err
        puts "#{DateTime.now.strftime('%m-%d-%Y %H:%M:%S')}|"\
             "Error opening cache file (#{err})"
        @cache = Henchman::Templates.cache
      end
      @cache[:history].default = DateTime.new
    end

    def config config
      @config = config
    end

    def update_ignore type, identifier
      return false if !(valid_ignore_type? type)
      @cache[:ignore][type][identifier] = Time.now.to_i
    end

    def ignore? type, identifier
      return false if !(valid_ignore_type? type)
      @cache[:ignore][type][identifier] >= (Time.now.to_i - @config[:reprompt_timeout])
    end

    def get_time_last_downloaded track
      id = track[:id].to_i
      (@cache[:history].include?(id)) ? @cache[:history][id] : DateTime.new
    end

    def tag track
      @cache[:history][track[:id].to_i] = DateTime.now
    end

    def delete track
      @cache[:history].delete track[:id].to_i
    end

    def flush
      File.open(@cache_file, "w") { |f| f.write( @cache.to_yaml ) }
    end

    def valid_ignore_type? type
      if !(Henchman::Templates.cache[:ignore].keys.include? type)
        puts "#{DateTime.now.strftime('%m-%d-%Y %H:%M:%S')}|"\
             "Invalid type '#{type}' for ignore cache check"
        false
      else
        true
      end
    end

    def clear type, value
      raise "Invalid type #{type}" if !@cache[:ignore].keys.include? type
      if @cache[:ignore][type].include? value
        @cache[:ignore][type].delete value
        puts "Deleting #{type} #{value} from cache"
      else
        puts "#{type} #{value} not found"
      end
      flush
    end

  end

end
