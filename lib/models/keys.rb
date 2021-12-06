module Cotcube
  class ReadCache
    module Helpers
      class KEYS

        def initialize(
          readcache,
          timezone = Cotcube::Helpers::CHICAGO
        )
          @readcache = readcache
          @timezone  = timezone
        end

        def update
          @datetime = @timezone.now
        end

        def payload
          # always returns the current keys live (no caching here)
          @readcache.cache.keys
        end

        def valid_until
          # is always valid
          @until = @timezone.now + 1.second
        end

        def created_at
          @datetime
        end

        def expired?
          valid_until < @timezone.now
        end

      end
    end
  end
end
