module Henchman
  class Templates
    def self.plist_main
      config = YAML.load_file(File.expand_path('~/.henchman/config'))

      "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n"\
      "<!DOCTYPE plist PUBLIC \"-//Apple//DTD PLIST 1.0//EN\" "\
      "\"http://www.apple.com/DTDs/PropertyList-1.0.dtd\">\n"\
      "<plist version=\"1.0\">\n"\
      "<dict>\n"\
      "\t<key>Label</key>\n"\
      "\t<string>henchman</string>\n"\
      "\t<key>ProgramArguments</key>\n"\
      "\t<array>\n"\
      "\t\t<string>#{File.expand_path('~/.henchman/run.sh')}</string>\n"\
      "\t</array>\n"\
      "\t<key>StartInterval</key>\n"\
      "\t<integer>#{config[:poll_itunes_open]}</integer>\n"\
      "\t<key>StandardOutPath</key>\n"\
      "\t<string>#{File.expand_path('~/.henchman/stdout.log')}</string>\n"\
      "\t<key>StandardErrorPath</key>\n"\
      "\t<string>#{File.expand_path('~/.henchman/stderr.log')}</string>\n"\
      "</dict>\n"\
      "</plist>"
    end

    def self.plist_clean
      "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n"\
      "<!DOCTYPE plist PUBLIC \"-//Apple//DTD PLIST 1.0//EN\" "\
      "\"http://www.apple.com/DTDs/PropertyList-1.0.dtd\">\n"\
      "<plist version=\"1.0\">\n"\
      "<dict>\n"\
      "\t<key>Label</key>\n"\
      "\t<string>henchman_clean</string>\n"\
      "\t<key>ProgramArguments</key>\n"\
      "\t<array>\n"\
      "\t\t<string>#{File.expand_path('~/.henchman/clean.sh')}</string>\n"\
      "\t</array>\n"\
      "\t<key>StartCalendarInterval</key>\n"\
      "\t<array>\n"\
      "\t<!-- Run twice a day. At 12:00 AM and at 12:00 PM -->\n"\
      "\t\t<dict>\n"\
      "\t\t\t<key>Hour</key>\n"\
      "\t\t\t<integer>00</integer>\n"\
      "\t\t\t<key>Minute</key>\n"\
      "\t\t\t<integer>00</integer>\n"\
      "\t\t</dict>\n"\
      "\t\t<dict>\n"\
      "\t\t\t<key>Hour</key>\n"\
      "\t\t\t<integer>12</integer>\n"\
      "\t\t\t<key>Minute</key>\n"\
      "\t\t\t<integer>00</integer>\n"\
      "\t\t</dict>\n"\
      "\t</array>\n"\
      "\t<key>StandardOutPath</key>\n"\
      "\t<string>#{File.expand_path('~/.henchman/stdout.log')}</string>\n"\
      "\t<key>StandardErrorPath</key>\n"\
      "\t<string>#{File.expand_path('~/.henchman/stderr.log')}</string>\n"\
      "</dict>\n"\
      "</plist>"
    end

    def self.shell_script command
      "#!/bin/sh\n"\
      "#{`which henchman`.chomp} #{command}"
    end

    def self.config
      {
        :dropbox => {:key => '',
                     :secret => '',
                     :access_token => '',
                     :user_id => '',
                     :root     => ''},
        :root => '',
        :poll_itunes_open => 10,
        :poll_track => 3,
        :reprompt_timeout => 300,
        :delimiter => '|~|',
        :delimiter_major => '|?|'
      }
    end

    def self.cache
      {
        :ignore => {
                     :artist   => Hash.new(0),
                     :playlist => Hash.new(0)
                   },
        :history => Hash.new
      }
    end
  end
end
