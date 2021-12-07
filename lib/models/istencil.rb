module Cotcube
  class ReadCache
    module Helpers
      class ISTENCIL

        def self.set_selected(selector)
          sel = selector.to_s.upcase.to_sym
          return :full     if selector.downcase.to_sym == :aa
          return :grains   if %i[ KE RS ZW ZS ZM ZL ZC ].include? sel
          return :meats    if %i[ HE LE GF             ].include? sel
          return :energies if %i[ HO RB NG CL          ].include? sel
          return :full     if %w[ A B D E J M N R S T  ].include? selector.to_s.upcase[0] and selector.to_s[1] == '6'
          return :full     if %i[ QR ES NQ YM ZN ZF ZT ].include? sel
          return :GC       if %i[ HG PL GC SI PA       ].include? sel
          return sel       if %i[ KC SB CC CT DX       ].include? sel
          return :error
        end

        def initialize(
          readcache,
          asset: :full,
          interval: 30.minutes,
          timezone: Cotcube::Helpers::CHICAGO,
          datetime: Cotcube::Helpers::CHICAGO.now  # meant for testing purposes, dont use in production
        )
          @datetime = datetime
          @interval = interval
          @timezone = timezone
          @asset    = asset
          @istencil = Cotcube::Level::Intraday_Stencil.new(interval: @interval, swap_type: :full, asset: @asset, datetime: @datetime)
        end

        def update
          @datetime = @timezone.now
          @next_eod = nil
          @until    = nil 
          @istencil = Cotcube::Level::Intraday_Stencil.new(interval: @interval, swap_type: :full, asset: @asset, datetime: @datetime)
        end

        def payload
          @istencil.base.select{|z| z[:x] > -6 }
        end

        # given now its  9:12, the current stencil.index would be at  8:30, its valid from  9:00 to  9:30, and it would switch to  9:00 at 9:30
        # given now its 16:01, the current stencil.index would be at 15:30, its valid from 16:00 to 17:30, and it would switch to 17:00 at 17:30
        #
        # the current stencil is valid until 30 minutes after the beginning  of next stencil

        def valid_until
          @until ||= @istencil.index(1)[:datetime] + @interval
        end

        alias_method :next_eop, :valid_until

        def expired?
          valid_until < @timezone.now
        end

        def modified_at;                   @datetime; end

        # the start of EOD is currently defined as 16:00 CT of the current business day (CBD). 
        #   What happens after 16:00 (or more precisely 17:00, as there is 1 hour of general
        #   EOD maintenance), belongs to next business day (NBD)
        #
        # if there is a dayswitch between i and i + 1, then we have found the EOD at i
        # likewise, if there is a gap around 16 between i and i + 1
        def next_eod
          unless @next_eod
            i = 1
            loop do 
              cur = @istencil.index(i  )[:datetime] + @interval
              nxt = @istencil.index(i+1)[:datetime] + @interval
              break if (cur.day != nxt.day && nxt - cur > 30.minutes) 
              break if (cur.hour <= 16 and nxt.hour >= 17)
              i += 1
            end 
            @next_eod = @istencil.index(i)[:datetime] + @interval
          else
            @next_eod
          end
        end

      end
    end
  end
end
