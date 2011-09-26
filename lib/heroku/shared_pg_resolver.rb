require "heroku/pg_resolver"

module PGResolver
  class SharedResolver < Resolver
    include PGResolver

    def self.shared_addon_prefix
      ENV["HEROKU_SHARED_DATABASE_ADDON_PREFIX"] || "HEROKU_SHARED_POSTGRESQL"
    end
  end
end
