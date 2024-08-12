**NOTE:** This plugin has been archived and is no longer maintained. It is not installable with the current node-based CLI.

# Heroku Shared Postgresql

This is a plugin to begin testing the client cli aspects of Yobuko.

    heroku plugins:install git@github.com:heroku/heroku-shared-postgresql.git

Most everything is modeled after Heroku Postgresql in order to have a
similar client experience. In fact a lot of this is just monkey
patched for the time being.

    Additional commands, type "heroku help COMMAND" for more details:

      pg:export [DATABASE] <OUTPUT_FILE>  # Export to <OUTPUT_FILE>
      pg:import [DATABASE] <INPUT_FILE>   # Import from <INPUT_FILE>
      pg:info [DATABASE]                  # Display database information
      pg:ingress [DATABASE]               # Show connection info
      pg:promote [DATABASE]               # Sets DATABASE as your DATABASE_URL
      pg:psql [DATABASE]                  # Open a psql shell to the database
      pg:reset [DATABASE]                 # Delete all data in DATABASE
      pg:reset_password [DATABASE]        # Reset the credentials on DATABASE
      pg:unfollow <REPLICA>               # stop a replica from following and make it a read/write database
      pg:wait [DATABASE]                  # monitor database creation, exit when complete
