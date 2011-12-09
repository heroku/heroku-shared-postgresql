require "heroku/pg_resolver"

module PGResolver
  class Resolver
    private

    def self.shared_addon_prefix
      ENV["HEROKU_SHARED_POSTGRESQL_ADDON_PREFIX"] || "HEROKU_SHARED_POSTGRESQL"
    end

    def self.parse_config(config_vars)
      dbs = {}
      config_vars.each do |key,val|
        case key
        when "DATABASE_URL"
          dbs['DATABASE'] = val
        when 'SHARED_DATABASE_URL'
          dbs['SHARED_DATABASE'] = val
        when /\A(#{shared_addon_prefix})_URL\Z/
          dbs[$1] = val
        when /\A(#{shared_addon_prefix}\w+)_URL\Z/
          dbs[$1] = val
        when /^(#{addon_prefix}\w+)_URL$/
          dbs[$1] = val
        end
      end
      return dbs
    end
  end
end
