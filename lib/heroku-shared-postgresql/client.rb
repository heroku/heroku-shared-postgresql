require "heroku/helpers"
require "digest/sha2"

 module HerokuSharedPostgresql
   class Client

     include Heroku::Helpers

     def initialize(url)
       @heroku_shared_postgresql_host = ENV["HEROKU_SHARED_POSTGRESQL_HOST"] || "https://yobuko.herokuapp.com"
       @heroku_shared_database_resource = RestClient::Resource.new(
         "#{@heroku_shared_database_host}/client",
         :headers => { :x_heroku_gem_version => Heroku::Client.version }
         )
       @database_sha = sha(url)
    end

    def reset_database
      http_put("/#{@database_sha}/reset-database")
    end

    def reset_role
      http_put("/#{@database_sha}/reset-password")
    end

    protected

    def sha(url)
      Digest::SHA2.hexdigest(url)
    end

    def sym_keys(c)
      if c.is_a?(Array)
        c.map {|e| sym_keys(e)}
      else
        c.inject({}) do |h, (k,v)|
          h[k.to_sym] = v; h
        end
      end
    end

    def checking_client_version
      begin
        yield
      rescue RestClient::BadRequest => e
        if message = json_decode(e.response.to_s)["upgrade_message"]
          abort(message)
        else
          raise e
        end
      end
    end

    def display_heroku_warning(response)
      warning = response.headers[:x_heroku_warning]
      display warning if warning
      response
    end

    def http_get(path)
      checking_client_version do
        retry_on_exception(RestClient::Exception) do
          response = @heroku_shared_database_resource[path].get
          display_heroku_warning response
          sym_keys(json_decode(response.to_s))
        end
      end
    end

    def http_post(path, payload = {})
      checking_client_version do
        response = @heroku_shared_database_resource[path].post(json_encode(payload))
        display_heroku_warning response
        sym_keys(json_decode(response.to_s))
      end
    end

    def http_put(path, payload = {})
      checking_client_version do
        response = @heroku_shared_database_resource[path].put(json_encode(payload))
        display_heroku_warning response
        sym_keys(json_decode(response.to_s))
      end
    end
  end
end
