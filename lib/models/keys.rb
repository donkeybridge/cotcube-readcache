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
          @datetime  = timezone.now
          @keys      = readcache.cache.keys
        end

        def update
          @keys      = @readcache.cache.keys
          @datetime  = @timezone.now
          @until     = @datetime + 20.seconds
        end

        def payload
          @keys
        end

        def valid_until
          # give a short validity, for testing purposes
          @until ||= @datetime + 20.seconds
        end

        def modified_at
          @datetime
        end

        def expired?
          valid_until < @timezone.now
        end

      end
    end
  end
end
