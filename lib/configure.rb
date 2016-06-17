require "templates"
require "yaml"
require "dropbox_sdk"
require "json"

module Henchman
  def self.configure
    config_file = File.expand_path('~/.henchman')
    if !File.exists?(config_file)
      config = Henchman::Templates.config
    else
      config = YAML.load_file(config_file)
    end

    if config[:dropbox][:key].empty? ||
       config[:dropbox][:secret].empty? ||
       config[:dropbox][:access_token].empty? ||
       agree("Update Dropbox configuration? (y/n) ")
      begin
        get_dropbox_credentials config
      rescue StandardError => err
        puts err
        return
      end
    end

    begin
      client = DropboxClient.new(config[:dropbox][:access_token])
      account_info = client.account_info()
      puts "Successfully connected to Dropbox: "
      puts "  #{account_info['display_name']} [#{account_info['email']}]"
    rescue StandardError => err
      puts "Error connecting to Dropbox account (#{err}). Try deleting the "\
           "henchman configuration file (`rm ~/.henchman`) and rerunning"\
           "`henchman configure`"
      return
    end

    if config[:dropbox][:root].empty? || agree()
      get_dropbox_root config, client
    end

    File.open(config_file, "w") { |f| f.write( config.to_yaml ) }
  end

  def self.get_dropbox_credentials config
    puts "You'll need to create your own Dropbox app to integrate. "\
         "Head over to https://www.dropbox.com/developers/apps. If "\
         "you have an app already that you'd like to use, click on "\
         "that app. If not, click on the 'Create App' link. From "\
         "here, choose 'Dropbox API', 'Full Dropbox', and finally "\
         "choose an app name.\n\n"\
         "Note your app key and app secret, and enter them below. "\
         "You will then be asked to login and give access to the app. "\
         "Once you have done this, copy the Authorization Code. You "\
         "will be prompted to enter it here.\n\n"

    dbx_cfg = config[:dropbox]
    dbx_cfg[:key]    = ask("Dropbox App Key: ")
    dbx_cfg[:secret] = ask("Dropbox App Secret: ")

    flow = DropboxOAuth2FlowNoRedirect.new(dbx_cfg[:key], dbx_cfg[:secret])
    authorize_url = flow.start()

    puts '1. Go to: ' + authorize_url
    puts '2. Click "Allow" (you might have to log in first)'
    puts '3. Copy the authorization code'

    code = ask("Enter the authorization code here: ")

    begin
      dbx_cfg[:access_token], dbx_cfg[:user_id] = flow.finish(code)
    rescue StandardError => msg
      dbx_cfg[:key]    = ''
      dbx_cfg[:secret] = ''
      raise "Invalid authorization code (#{msg})"
    end
  end

  def self.get_dropbox_root(config, client)
    # paths = Hash.new
    # build_dropbox_dirs(paths, client, '/', 0)
    not_done = true
    while not_done
      path = ask("Enter the path to your music directory in Dropbox: (? for help)" )
      if path == '?'
        puts "The path to your music directory is a unix-like path. For example: "\
             "/Some/Directory/Music"
        next
      end

      begin
        metadata = client.metadata(path.chomp!('/'))
        config[:dropbox][:root] = path
        puts "Valid path!"
        not_done = false
      rescue StandardError => err
        print "Invalid path. "
        not_done = agree("Try again? (y/n) ")
      end
    end
  end

  # def self.build_dropbox_dirs(paths, client, path, level)
  #   return if level == 2
  #   metadata = client.metadata(path)
  #   metadata['contents'].each do |elem|
  #     next if !elem['is_dir']
  #     paths[elem['path']] = Hash.new
  #     build_dropbox_dirs(paths[elem['path']], client, elem['path'], level+1)
  #   end
  # end
end
