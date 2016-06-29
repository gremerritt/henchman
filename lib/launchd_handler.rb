require 'open-uri'

module Henchman

  class LaunchdHandler

    def self.start
      if !internet_connection?
        puts "No internet connection detected - unable to verify correct configuration."
        return if !agree("Launch henchman anyways? (y/n) ")
      else
        puts "Checking configuration"
        return if !Henchman.connect
      end

      puts "Creating agents"
      plist_main       = Henchman::Templates.plist_main
      plist_path_main  = File.expand_path("~/Library/LaunchAgents/com.henchman.plist")
      plist_clean      = Henchman::Templates.plist_clean
      plist_path_clean = File.expand_path("~/Library/LaunchAgents/com.henchman.clean.plist")
      shell_script_path_main  = File.expand_path("~/.henchman/run.sh")
      shell_script_path_clean = File.expand_path("~/.henchman/clean.sh")
      cache_path        = File.expand_path("~/.henchman/cache")
      File.write(plist_path_main, plist_main)
      File.write(shell_script_path_main, Henchman::Templates.shell_script('run'))
      File.write(plist_path_clean, plist_clean)
      File.write(shell_script_path_clean, Henchman::Templates.shell_script('clean'))
      File.open(cache_path, "w") { |f| f.write( Henchman::Templates.cache.to_yaml ) }

      puts "Launching agent"
      `chmod +x #{shell_script_path_main}`
      `chmod +x #{shell_script_path_clean}`
      `launchctl load #{plist_path_main}`
      `launchctl load #{plist_path_clean}`

      puts "Launched successfully! You are now running henchman."
    end

    def self.stop
      puts "Stopping agents"
      plist_path_main = File.expand_path("~/Library/LaunchAgents/com.henchman.plist")
      plist_path_clean = File.expand_path("~/Library/LaunchAgents/com.henchman.clean.plist")
      `launchctl unload #{plist_path_main}`
      `launchctl unload #{plist_path_clean}`
      `rm #{plist_path_main}`
      `rm #{plist_path_clean}`
      `rm #{File.expand_path("~/.henchman/run.sh")}`
      `rm #{File.expand_path("~/.henchman/clean.sh")}`
      `rm #{File.expand_path("~/.henchman/cache")}`
      `rm #{File.expand_path("~/.henchman/stdout.log")}`
      `rm #{File.expand_path("~/.henchman/stderr.log")}`

      puts "Successfully stopped henchman"
    end

    def self.internet_connection?
      begin
        true if open("https://www.dropbox.com/")
      rescue
        false
      end
    end

  end

end
