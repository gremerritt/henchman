require "templates"
require "yaml"
require "dropbox_sdk"

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

    if config[:dropbox][:root].empty? || agree()
      begin
        get_dropbox_root config
      end
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

  def self.get_dropbox_root config
    client = DropboxClient.new(config[:dropbox][:access_token])
    puts "linked account:", client.account_info().inspect
  end
end
