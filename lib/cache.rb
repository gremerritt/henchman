module Henchman

  class Cache

    def initialize
      begin
        @cache_file = File.expand_path("~/.henchman/cache")
        @cache = YAML.load_file(@cache_file)
        raise "Incorrectly formatted cache" if !(@cache.include? :ignore)

        @cache[:ignore].each_value { |val| val.default = 0 }
      rescue StandardError => err
        puts "Error opening cache file (#{err})"
        @cache = Henchman::Templates.cache
      end
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

    def tag track
      @cache[:history][track[:id].to_i] = Time.now.to_i
    end

    def delete track
      @cache[:history].delete track[:id].to_i
    end

    def flush
      File.open(@cache_file, "w") { |f| f.write( @cache.to_yaml ) }
    end

  end

end
