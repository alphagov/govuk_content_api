require "redis-rack-cache"

module Rack
  module Cache

    # Make sure we always set a TTL for entries, even if it's longer than we're
    # expecting in any response, so Redis knows what it can safely clean out
    REDIS_DEFAULT_TTL = 3600 * 24

    class EntityStore
      class Redis < RedisBase

        # Patched version of this method to always set a TTL, so Redis knows it
        # can purge the value if it gets full.
        # See <https://github.com/redis-store/redis-rack-cache/blob/ef9173cd1a68b5d5f65ed5502e92f7c14cb765de/lib/rack/cache/redis_entitystore.rb#L35-44>
        def write(body, ttl=0)
          buf = StringIO.new
          key, size = slurp(body){|part| buf.write(part) }

          if ttl.zero?
            [key, size] if cache.setex(key, REDIS_DEFAULT_TTL, buf.string)
          else
            [key, size] if cache.setex(key, ttl, buf.string)
          end
        end
      end
    end

    class MetaStore
      class Redis < RedisBase
        # Patched version of this method to always set a TTL, so Redis knows it
        # can purge the value if it gets full.
        # See <https://github.com/redis-store/redis-rack-cache/blob/ef9173cd1a68b5d5f65ed5502e92f7c14cb765de/lib/rack/cache/redis_metastore.rb#L32-34>
        def write(key, entries)
          cache.setex(hexdigest(key), REDIS_DEFAULT_TTL, entries)
        end
      end
    end
  end
end

# The namespace extension for Redis::Store doesn't override the `setex`
# operation as it should, so when we set expiry times with `setex`, we break
# the namespacing. This fixes that.
# See <https://github.com/redis-store/redis-store/blob/f3c16080416a93df36eaa63a6a703409c968d250/lib/redis/store/namespace.rb>
# for the Namespace overrides.
class Redis
  class Store < self
    module Namespace
      def setex(key, expiry, val, options = nil)
        namespace(key) { |key| super(key, expiry, val, options) }
      end
    end
  end
end
