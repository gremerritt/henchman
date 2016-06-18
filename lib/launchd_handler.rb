# require "configure"

module Henchman

  class LaunchdHandler

    def self.start
      return if !connect
      puts "here"
    end

    def self.stop

    end
  end

end
