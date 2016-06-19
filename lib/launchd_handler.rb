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

      puts "Creating agent"
      plist      = Henchman::Templates.plist
      plist_path = File.expand_path("~/Library/LaunchAgents/com.henchman.plist")
      shell_script_path = File.expand_path("~/.henchman/run.sh")
      File.write(plist_path, plist)
      File.write(shell_script_path, Henchman::Templates.shell_script)

      puts "Launching agent"
      `chmod +x #{shell_script_path}`
      `launchctl load #{plist_path}`

      puts "Launched successful! You are now running henchman."
    end

    def self.stop
      puts "Stopping agents"
      plist_path = File.expand_path("~/Library/LaunchAgents/com.henchman.plist")
      `launchctl unload #{plist_path}`
      `rm #{plist_path}`
      `rm #{File.expand_path("~/.henchman/run.sh")}`
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
