require "heroku/pg_resolver"

module PGResolver
  class SharedResolver < Resolver
    include PGResolver

    def self.shared_addon_prefix
      ENV["HEROKU_SHARED_DATABASE_ADDON_PREFIX"] || "HEROKU_SHARED_POSTGRESQL"
    end

    private

    def self.parse_config(config_vars)
      dbs = {}
      config_vars.each do |key,val|
        case key
        when "DATABASE_URL"
          dbs['DATABASE'] = val
        when 'SHARED_DATABASE_URL'
          dbs['SHARED_DATABASE'] = val
        when /^(#{shared_addon_prefix}\w+)_URL$/
          dbs["HEROKU_SHARED_POSTGRESQL"] = val
        when /^(#{addon_prefix}\w+)_URL$/
          dbs[$+] = val # $+ is the last match
        end
      end
      return dbs
    end
  end
end
