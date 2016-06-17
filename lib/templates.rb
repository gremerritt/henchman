module Henchman
  class Templates
    def plist

    end

    def config
      yml = {
              'dropbox' => {'username' => '',
                            'password' => '',
                            'root'     => ''},
              'root' => '',
              'poll_itunes_open' => 10,
              'poll_track' => 3,
              'reprompt_timeout' => 300
            }
    end
  end
end
