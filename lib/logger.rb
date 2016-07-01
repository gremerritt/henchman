module Henchman

  class Logger

    def log msg
      puts "#{DateTime.now.strftime('%m-%d-%Y %H:%M:%S')}|#{msg}"
    end

  end

end
