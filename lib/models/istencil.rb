module Cotcube
  class ReadCache
    module Entities
      class ISTENCIL < BasicEntity

        INTERVAL = 30.minutes

        def self.set_selected(selector)
          sel = selector.to_s.upcase[..1].to_sym rescue 'ZZ'
          return :full     if sel == :AA
          return :grains   if %i[ KE RS ZW ZS ZM ZL ZC ].include? sel
          return :meats    if %i[ HE LE GF             ].include? sel
          return :energies if %i[ HO RB NG CL          ].include? sel
          return :full     if %w[ A B D E J M N R S T  ].include? selector.to_s.upcase[0] and selector.to_s[1] == '6'
          return :full     if %i[ QR ES NQ YM ZN ZF ZT ].include? sel
          return :GC       if %i[ HG PL GC SI PA       ].include? sel
          return sel       if %i[ KC SB CC CT DX       ].include? sel
          return :error
        end

        def update
          @next_eod = nil
          @next_eow = nil
          @istencil = Cotcube::Level::Intraday_Stencil.new(interval: INTERVAL , swap_type: :full, asset: asset, datetime: timezone.now)
          @payload  = istencil.base.select{|z| z[:x] > -6 }
          super
        end

        def valid_until
          @istencil ||= Cotcube::Level::Intraday_Stencil.new(interval: INTERVAL , swap_type: :full, asset: asset, datetime: timezone.now)
             @until ||= istencil.index(1)[:datetime] + INTERVAL
        end

        alias_method :next_eop, :valid_until

        # the start of EOD is currently defined as 16:00 CT of the current business day (CBD). 
        #   What happens after 16:00 (or more precisely 17:00, as there is 1 hour of general
        #   EOD maintenance), belongs to next business day (NBD)
        #
        # if there is a dayswitch between i and i + 1, then we have found the EOD at i
        # likewise, if there is a gap around 16 between i and i + 1
        def next_eod
          if @next_eod.nil?
            i = 1
            loop do 
              cur = istencil.index(i  )[:datetime] + INTERVAL
              nxt = istencil.index(i+1)[:datetime] + INTERVAL
              break if (cur.day != nxt.day && (nxt - cur) * 1.day > INTERVAL)
              break if (cur.hour <= 16 and nxt.hour >= 17)
              i += 1
            end 
            @next_eod = istencil.index(i)[:datetime] + INTERVAL 
          else
            @next_eod
          end
        end

        def next_eow
          stencil = readcache.cache['stencil'][:obj]
          now = timezone.now
          unless @next_eow
            i = 0
            i+= 1 while stencil.index(i+1)[:datetime] < now.next_week.beginning_of_week
            @next_eow = stencil.index(i)[:datetime]   + next_eod.hour.hours + next_eod.min.minutes
          else
            @next_eow
          end
        end
        private
        attr_reader :istencil


      end
    end
  end
end
