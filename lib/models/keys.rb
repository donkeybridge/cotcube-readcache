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
          @classes   = Cotcube::ReadCache::Helpers.constants.select {|c| Cotcube::ReadCache::Helpers.const_get(c).is_a? Class}
        end

        def update
          @keys      = readcache.cache.keys
          @classes   = Cotcube::ReadCache::Helpers.constants.select {|c| Cotcube::ReadCache::Helpers.const_get(c).is_a? Class}
          @datetime  = timezone.now
          @until     = nil
        end

        def payload
          { classes: classes, missing: Cotcube::ReadCache::VALID_ENTITIES.keys.map{|z| z.to_s.upcase.to_sym } - classes, keys: keys }
        end

        def valid_until
          # give a short validity, for testing purposes
          @until ||= datetime + 20.seconds
        end

        def modified_at
          datetime
        end

        def expired?
          valid_until < timezone.now
        end

        private
        attr_reader :keys, :classes, :timezone, :datetime, :readcache

      end
    end
  end
end
