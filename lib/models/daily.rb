module Cotcube
  class ReadCache
    module Helpers
      class DAILY

	def initialize(
	  readcache,                               # backreference to the caller
	  contract:, 
	  timezone: Cotcube::Helpers::CHICAGO
	)
	  @readcache = readcache
	  @timezone  = timezone
          @contract  = contract
          @interval  = 1.day
	  update
	end

	def update
	  @datetime = timezone.now
          @until = nil
	  @sym ||= Cotcube::Helpers.get_id_set(symbol: contract[..1])

	  continuous = %w[currencies interest indices].include? sym[:type]

	  indicators = {
            dist:          Cotcube::Indicators.calc(a:  :high,  b: :low, finalize: :to_i) {|high, low| (high - low) / sym[:ticksize] },
            ema50_high:    Cotcube::Indicators.ema(key: :high,  length:  50,  smoothing: 2),
	    ema50_low:     Cotcube::Indicators.ema(key: :low,   length:  50,  smoothing: 2),
            ema200_close:  Cotcube::Indicators.ema(key: :low,   length: 200,  smoothing: 2),
            ema250_close:  Cotcube::Indicators.ema(key: :low,   length: 250,  smoothing: 2)
	  }

	  base = if continuous
	    Cotcube::Bardata.continuous(symbol: contract[..1], indicators: indicators)[-300..].
	      map{ |z|
	        z[:datetime] = timezone.parse(z[:date])
	        z.delete(:contracts)
	        z
	      }
		 else
		   Cotcube::Bardata.provide_daily(contract: contract, indicators: indicators)[-300..]
		 end

	  base.select!{|z| z[:high]}

	  scaleBreaks = []
	  brb = readcache.deliver(:stencil)[:payload] 
	  brb.each_with_index.map{|z,i|
	    next if i.zero?
	    if brb[i][:datetime] - brb[i-1][:datetime] > interval and 
               brb[i][:datetime] > base.first[:datetime] and 
               brb[i-1][:datetime] < base.last[:datetime]

              scaleBreaks << { startValue: brb[i-1][:datetime] + 0.5 * interval, endValue: brb[i][:datetime] - 0.5 * interval }
	    end
	  } unless base.empty?

          @pkg = { base: base, breaks: scaleBreaks }
	end

	def payload
          pkg
	end

	def valid_until
          @until ||= readcache.next_eod(contract)
	end

	def modified_at
	  @datetime
	end

	def expired?
	  valid_until < timezone.now
	end

        private 
        attr_accessor :sym, :contract, :pkg, :interval, :readcache, :timezone

      end
    end
  end
end
