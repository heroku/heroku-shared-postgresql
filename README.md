# Heroku Shared Postgresql (Yobuko)

This is a plugin to begin testing the client cli aspects of Yobuko.

    heroku plugins:install git@github.com:heroku/heroku-shared-postgresql.git

Most everything is modeled after Heroku Postgresql in order to have a
similar client experience. In fact a lot of this is just monkey
patched for the time being.

    Additional commands, type "heroku help COMMAND" for more details:

      sharedpg:info            # Show stats on DATABASE
      sharedpg:promote         # sets HEROKU_SHARED_POSTGRESQL_URL as your DATABASE_URL
      sharedpg:reset           # Delete all data in DATABASE
      sharedpg:reset_password  # Reset the password on the database
