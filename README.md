# Heroku Shared Postgresql (Yobuko)

This is a plugin to begin testing the client cli aspects of Yobuko.

    heroku plugins:install git@github.com:heroku/heroku-shared-postgresql.git

Most everything is modeled after Heroku Postgresql in order to have a
similar client experience. In fact a lot of this is just monkey
patched for the time being.

`reset_role` and `reset` are currently working. We will be adding
other features as we move forward.
