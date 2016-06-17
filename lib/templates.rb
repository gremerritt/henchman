module Henchman
  class Templates
    def self.plist

    end

    def self.config
      yml = {
              :dropbox => {:key => '',
                           :secret => '',
                           :access_token => '',
                           :user_id => '',
                           :root     => ''},
              :root => '',
              :poll_itunes_open => 10,
              :poll_track => 3,
              :reprompt_timeout => 300
            }
    end
  end
end
