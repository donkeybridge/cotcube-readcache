module Cotcube
  class ReadCache
    module Helpers
      class STENCIL

        def initialize(
          readcache,
          interval:  :daily,
          swap_type: :full,
          timezone:  Cotcube::Helpers::CHICAGO
        )
          @timezone  = timezone
          @interval  = interval
          @swap_type = swap_type
          @readcache = readcache
          update
        end

        def update
          @datetime = timezone.now
          @until    = nil
          @stencil = Cotcube::Level::EOD_Stencil.new(swap_type: swap_type, timezone: timezone, interval: interval)
        end

        def payload
          stencil.base.select{|z| z[:x] > -6 and z[:x] < 1500 }
        end

        # the current stencil is valid until next_eod

        def valid_until
          @until ||= readcache.next_eod
        end

        def expired?
          valid_until < timezone.now
        end

        def modified_at;                   datetime; end

        def index(i=0)
          stencil.index(i)
        end

        private
        attr_reader :datetime, :readcache, :timezone, :date, :stencil, :interval, :swap_type

      end
    end
  end
end
