module Cotcube
  class ReadCache
    module Entities
      class KEYS < BasicEntity

        def update
          keys      = readcache.cache.keys
          classes   = Cotcube::ReadCache::Entities.constants.select {|c| Cotcube::ReadCache::Entities.const_get(c).is_a? Class}
          @payload = { classes: classes, missing: Cotcube::ReadCache::VALID_ENTITIES.keys.map{|z| z.to_s.upcase.to_sym } - classes, keys: keys }
          super
        end

        def valid_until
          @until ||= modified + 20.seconds
        end

      end
    end
  end
end
