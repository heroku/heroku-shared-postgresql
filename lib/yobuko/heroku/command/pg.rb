require "heroku/command/base"
require "heroku/pgutils"
require "heroku/command/pg"
require "heroku-postgresql/client"
require "yobuko/heroku/pg_resolver"
require "yobuko/heroku-shared-postgresql/client"

module Heroku::Command
  class Pg < BaseWithApp
    include PgUtils
    include PGResolver

    # pg:ingress [DATABASE]
    #
    # allow direct connections to the database from this IP for one minute
    #
    # (dedicated only)
    # defaults to DATABASE_URL databases if no DATABASE is specified
    #
    def ingress
      deprecate_dash_dash_db("pg:ingress")
      uri = generate_ingress_uri
      display "Connection info string:"
      display "   \"dbname=#{uri.path[1..-1]} host=#{uri.host} port=#{uri.port} user=#{uri.user} password=#{uri.password} sslmode=require\""
    end

    # pg:promote <DATABASE>
    #
    # sets DATABASE as your DATABASE_URL
    #
    def promote
      deprecate_dash_dash_db("pg:promote")
      follower_db = resolve_db(:required => 'pg:promote')
      error("DATABASE_URL is already set to #{follower_db[:name]}") if follower_db[:default]

      working_display "-----> Promoting #{follower_db[:name]} to DATABASE_URL" do
        heroku.add_config_vars(app, {"DATABASE_URL" => follower_db[:url]})
      end
    end

    # pg:reset <DATABASE>
    #
    # delete all data in DATABASE
    def reset
      deprecate_dash_dash_db("pg:reset")
      db = resolve_db(:required => 'pg:reset')

      display "Resetting #{db[:pretty_name]}"
      return unless confirm_command

      working_display 'Resetting' do
        case db[:name]
        when Resolver.shared_addon_prefix
          display " getting new database credentials...", false
          response = heroku_shared_postgresql_client(db[:url]).reset_database
          detected_app = app
          heroku.add_config_vars(detected_app, response)
          heroku.add_config_vars(detected_app, {"DATABASE_URL" => response['url']}) if db[:default]
          display " done", false

          begin
            release = heroku.releases(detected_app).last
            display(", #{release["name"]}", false) if release
          rescue RestClient::RequestFailed => e
          end
          display "."
        when "SHARED_DATABASE"
          heroku.database_reset(app)
        else
          heroku_postgresql_client(db[:url]).reset
        end
      end
    end

    # pg:reset_password <DATABASE>
    #
    # Reset the password on the database
    #
    def reset_password
      db = resolve_db
      display "Resetting password on #{db[:pretty_name]}"
      return unless confirm_command
      working_display 'Resetting password' do
        case db[:name]
        when "SHARED_DATABASE"
          output_with_bang "Resetting password is not supported on SHARED_DATABASE"
        when Resolver.shared_addon_prefix
          response = heroku_shared_postgresql_client(db[:url]).reset_password
          detected_app = app
          display "Setting new password...", false
          heroku.add_config_vars(detected_app, response)
          heroku.add_config_vars(detected_app, {"DATABASE_URL" => response['url']}) if db[:default]
          display " done", false
          begin
            release = heroku.releases(detected_app).last
            display(", #{release["name"]}", false) if release
          rescue RestClient::RequestFailed => e
          end
          display "."
        else
          error "Resetting password is not yet supported on #{db[:name]}"
        end
      end
    end

    # pg:unfollow <REPLICA>
    #
    # stop a replica from following and make it a read/write database
    #
    def unfollow
      follower_db = resolve_db(:required => 'pg:unfollow')

      if ["SHARED_DATABASE", Resolver.shared_addon_prefix].include? follower_db[:name]
        output_with_bang "#{follower_db[:name]} does not support forking and following."
      end

      follower_name = follower_db[:pretty_name]
      follower_db_info = heroku_postgresql_client(follower_db[:url]).get_database
      origin_db_url = follower_db_info[:following]

      unless origin_db_url
        output_with_bang "#{follower_name} is not following another database"
        return
      end

      origin_name = name_from_url(origin_db_url)

      output_with_bang "#{follower_name} will become writable and no longer"
      output_with_bang "follow #{origin_name}. This cannot be undone."
      return unless confirm_command

      working_display "Unfollowing" do
        heroku_postgresql_client(follower_db[:url]).unfollow
      end
    end

private

    def heroku_shared_postgresql_client(url)
      HerokuSharedPostgresql::Client.new(url)
    end

    def wait_for(db)
      return if ["SHARED_DATABASE", Resolver.shared_addon_prefix].include? db[:name]

      ticking do |ticks|
        wait_status = heroku_postgresql_client(db[:url]).get_wait_status
        break if !wait_status[:waiting?] && ticks == 0
        redisplay("Waiting for database %s... %s%s" % [
                    db[:pretty_name],
                    wait_status[:waiting?] ? "#{spinner(ticks)} " : "",
                    wait_status[:message]],
                  !wait_status[:waiting?]) # only display a newline on the last tick
        break unless wait_status[:waiting?]
      end
    end

    def display_db_info(db)
      display("=== #{db[:pretty_name]}")
      case db[:name]
      when "SHARED_DATABASE"
        display_info_shared
      when Resolver.shared_addon_prefix
        display_info_shared_postgresql(db)
      else
        display_info_dedicated(db)
      end
    end

    def display_info_shared_postgresql(db)
      response = heroku_shared_postgresql_client(db[:url]).show_info
      response.each do |key, value|
        display " #{key.gsub('_', ' ').capitalize}: #{value ? value : 0}"
      end
    end

    def generate_ingress_uri(action)
      db = resolve_db(:allow_default => true)
      case db[:name]
      when "SHARED_DATABASE"
        error "Cannot ingress to a shared database" if "SHARED_DATABASE" == db[:name]
      when Resolver.shared_addon_prefix
        working_display("#{action} to #{db[:name]}")
        return URI.parse(db[:url])
      else
        hpc = heroku_postgresql_client(db[:url])
        error "The database is not available for ingress" unless hpc.get_database[:available_for_ingress]
        working_display("#{action} to #{db[:name]}") { hpc.ingress }
        return URI.parse(db[:url])
      end
    end
  end
end
