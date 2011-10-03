require "heroku/command/base"
require "heroku/pgutils"
require "heroku/spg_resolver"
require "heroku-postgresql/client"

module Heroku::Command
  # manage heroku shared database offering
  #
  class SharedPg < BaseWithApp
    include PgUtils
    include SPGResolver

    # sharedpg:reset <DATABASE>
    #
    # delete all data in DATABASE
    def reset
      db = resolve_db(:required => 'pg:reset')

      display "Resetting #{db[:pretty_name]}"
      return unless confirm_command

      working_display 'Resetting' do
        case db[:name]
        when "SHARED_DATABASE"
          heroku.database_reset(app)
        when Resolver.shared_addon_prefix
          token = resolve_auth_token
          heroku_shared_postgresql_client(db[:url]).reset
        else
          heroku_postgresql_client(db[:url]).reset
        end
      end
    end

    # sharedpg:reset_role <DATABASE>
    #
    # reset the role on the database (atomic)
    #
    # defaults to HEROKU_SHARED_URL if no DATABASE is specified
    #
    def reset_role
      db = resolve_db(:required => 'pg:reset_role')

      display "Resetting role on #{db[:pretty_name]}"
      return unless confirm_command

      working_display 'Resetting role' do
        case db[:name]
        when "SHARED_DATABASE"
          display " !    Resetting role is not supported on current SHARED_DATABASE version"
        when Resolver.shared_addon_prefix
          token = resolve_auth_token
          heroku_shared_postgresql_client(db[:url]).reset_role
        else
          display " !    Resetting role is not supported on #{db[:name]}"
        end
      end
    end

    private

    def heroku_shared_postgresql_client(url)
      HerokuSharedPostgresql::Client.new(url)
    end
  end
end
