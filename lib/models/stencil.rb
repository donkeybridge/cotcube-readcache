module Cotcube
  class ReadCache
    module Helpers
      class STENCIL

        def initialize(
          readcache,
          interval:  :daily,
          swap_type: :full,
          date:      nil,
          timezone:  Cotcube::Helpers::CHICAGO
        )
          @timezone  = timezone
          @interval  = interval
          @date      = date
          @swap_type = swap_type
          @readcache = readcache
          @stencil   = Cotcube::Level::EOD_Stencil.new(swap_type: swap_type, date: @date, timezone: @timezone, interval: @interval)
        end

        def update
          @datetime = @timezone.now
          @until    = @readcache.next_eod
          @next_eow = nil
          @stencil = Cotcube::Level::EOD_Stencil.new(swap_type: swap_type, date: @date, timezone: @timezone, interval: @interval)
        end

        def payload
          @stencil.base.select{|z| z[:x] > -6 }
        end

        # the current stencil is valid until next_eod

        def valid_until
          @until ||= @readcache.next_eod
        end

        alias_method :next_eop, :valid_until

        def expired?
          valid_until < @timezone.now
        end

        def modified_at;                   @datetime; end

        def next_eow
          eod = @readcache.next_eod
          now = @timezone.now
          unless @next_eow
            i = 0
            i+= 1 while @stencil.index(i+1)[:datetime] < now.next_week.beginning_of_week
            @next_eow = @stencil.index(i)[:datetime] + eod.hour.hours  + eod.min.minutes
          else
            @next_eow
          end
        end

      end
    end
  end
end
