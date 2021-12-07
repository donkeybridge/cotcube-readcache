module Cotcube
  class ReadCache
    module Helpers
      class TEMPLATE

        def initialize(
          readcache,                               # backreference to the caller
          timezone: Cotcube::Helpers::CHICAGO,
          datetime: Cotcube::Helpers::CHICAGO.now  # meant for testing purposes, dont use in production
        )
          @readcache = readcache
          @datetime  = datetime
          @timezone  = timezone
          # < initialization >
        end

        def update
          @datetime = timezone.now
          # < update >
        end

        def payload
          # < payload >
        end

        def valid_until
          @until ||= nil # < based on stencil or istencil >
        end

        def modified_at
          datetime
        end

        def expired?
          valid_until < timezone.now
        end

        private
        attr_reader :datetime, :timezone, :readcache


      end
    end
  end
end
