# Henchman

Henchman is an application which sits on top of iTunes on OS X. It dynamically syncs in music from Dropbox. This way, all music can be kept in the cloud yet you can still use iTunes as your music player.

When you (single) click on a track in iTunes the application will check if that track is available locally. If it is not the application will check if the file is available in Dropbox, and it will be downloaded automatically.

## Installation

Install it yourself as:

    $ gem install henchman-sync

## Usage

Run:

    $ henchman configure

This will guide you through setting up the application, including linking your Dropbox. From here you can run:

    $ henchman start

This starts the henchman daemon. You can now select a track in iTunes which is not available locally, and you will be asked if you'd like to fetch the track from your Dropbox. The application will also automatically download the rest of the album that contains the track you selected.

You can also click on a playlist, and if that playlist has tracks that are not available locally, they will be downloaded for you.

Starting the henchman daemon will also create a task to cleanse your iTunes tracks twice per day*. The task runs at 12:00 AM and PM (or as soon as possible if the machine was asleep at that time.) Any track that hasn't been played in more than 24 hours AND wasn't downloaded in the last 24 hours will be removed from your machine. You can also run the clean manually by running

    $ henchman clean

You can also run

    $ henchman clean --played_date 'true'

To remove tracks that haven't been played in the last 24 hours (ignoring when the track was last downloaded.)

* = as of version 0.3.0 - if you were running an earlier version simply stop and re-start henchman

## Troubleshooting

Running the `configure` command creates a `~/.henchman` direction. This directory contains your configuration file, as well as log files and a shell scripts used for running the application. If nothing appears to be happening in iTunes after running `henchman start` your best bet is to check the log files.

By default, the application checks if iTunes is open every 10 seconds. If it is, it continues to poll iTunes every 3 seconds to see if a track is selected. If you'd like to change these, you can edit the `config` YAML file. If you edit the `poll_itunes_open` setting, you'll need to stop and re-start the henchman daemon.

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## TODO

  - Move off of the 'dropbox-sdk' gem, since it uses their API V1, which will be depreciated June 28th, 2017 (or just buck up and update the gem myself)

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/gremerritt/henchman.


## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).
