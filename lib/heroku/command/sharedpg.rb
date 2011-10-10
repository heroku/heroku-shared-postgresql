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

    # sharedpg:info <DATABASE>
    #
    # Show stats on DATABASE
    def info
      db = resolve_db(:required => 'sharedpg:info')

      display "Statistics for #{db[:pretty_name]}"

      display "Acquiring info..."
      case db[:name]
      when Resolver.shared_addon_prefix
        response = heroku_shared_postgresql_client(db[:url]).show_info
        response.each do |key, value|
          display " #{key.gsub('_', ' ').capitalize}: #{value ? value : 0}"
        end
        display "Done", true
      end
    end

    # sharedpg:reset <DATABASE>
    #
    # delete all data in DATABASE
    def reset
      db = resolve_db(:required => 'sharedpg:reset')

      display "Resetting #{db[:pretty_name]}"
      return unless confirm_command

      working_display 'Resetting' do
        case db[:name]
        when Resolver.shared_addon_prefix
          display " getting new database credentials...", false
          response = heroku_shared_postgresql_client(db[:url]).reset_database
          detected_app = app
          heroku.add_config_vars(detected_app, response)
          display " done", false

          begin
            release = heroku.releases(detected_app).last
            display(", #{release["name"]}", false) if release
          rescue RestClient::RequestFailed => e
          end
          display "."
        else
          display " !    Resetting database is not supported on #{db[:name]}"
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
      db = resolve_db(:required => 'sharedpg:reset_role')

      display "Resetting role on #{db[:pretty_name]}"
      return unless confirm_command

      working_display 'Resetting role' do
        case db[:name]
        when "SHARED_DATABASE"
          display " !    Resetting role is not supported on current SHARED_DATABASE version"
        when Resolver.shared_addon_prefix
          response = heroku_shared_postgresql_client(db[:url]).reset_role
          detected_app = app
          display "Setting new password...", false
          heroku.add_config_vars(detected_app, response)
          display " done", false

          begin
            release = heroku.releases(detected_app).last
            display(", #{release["name"]}", false) if release
          rescue RestClient::RequestFailed => e
          end
          display "."
        else
          display " !    Resetting role is not supported on #{db[:name]}"
        end
      end
    end

    private

    def working_display(msg)
      redisplay "#{msg}..."
      yield if block_given?
      redisplay "#{msg}... done\n"
    end

    def heroku_shared_postgresql_client(url)
      HerokuSharedPostgresql::Client.new(url)
    end
  end
end
