module Cotcube
  class ReadCache
    module Helpers
      class INTRA

        def initialize(
          readcache,                               # backreference to the caller
          contract:,
          timezone: Cotcube::Helpers::CHICAGO
        )
          @readcache = readcache
          @timezone  = timezone
          @interval  = 30.minutes
          @contract  = contract 
          update
        end

        def update
          @datetime = @timezone.now
          @until = nil
          @sym ||= Cotcube::Helpers.get_id_set(symbol: contract[..1])
          other_tz = if %w[ NYBOT NYMEX ].include? sym[:exchange]
                       'America/New_York'
                     elsif %w[ DTB ].include? sym[:exchane]
                       'Europe/Berlin'
                     else
                       'America/Chicago'
                     end

          if pkg.nil?
            raw   = JSON.parse(Cotcube::Helpers::DataClient.new.get_historical(contract: contract, interval: :min30, duration: '30_D' ), symbolize_names: true)
            puts "ERROR: #{raw}" unless raw[:error].zero?
            base  = raw[:base].
              map{ |z|
                z[:datetime] = timezone.parse(z[:time])
                %i[time created_at wap trades].each{|k| z.delete(k)}
              z
            }.select{|z| z[:high] } rescue []
          else
            raw   = JSON.parse(Cotcube::Helpers::DataClient.new.get_historical(contract: contract, interval: :min30, duration: '6_H' ), symbolize_names: true)
            puts "ERROR: #{raw}" unless raw[:error].zero?
            base      = pkg[:base]
            new_base  = raw[:base].
              map{ |z|
              z[:datetime] = DateTime.parse(z[:time])
              %i[time created_at wap trades].each{|k| z.delete(k)}
              z
            }.select{|z| z[:high] } rescue []
            new_base.each {|z| base << z if base.last[:datetime] < z[:datetime] }
          end

          scaleBreaks = []
          brb   = readcache.deliver(:istencil, selector: contract[..1])[:payload]
          brb.each_with_index.map{|z,i|
            next if i.zero?
            if (brb[i][:datetime] - brb[i-1][:datetime]) * 24.hours > interval and brb[i][:datetime] > base.first[:datetime] and brb[i-1][:datetime] < base.last[:datetime]
              scaleBreaks << { startValue: brb[i-1][:datetime] + 0.5 * interval, endValue: brb[i][:datetime] - 0.5 * interval }
            end
          } unless base.empty?

          @pkg = { base: base, breaks: scaleBreaks }
        end

        def payload
          pkg
        end

        def valid_until
          @until ||= @readcache.next_eop(contract)
        end

        def modified_at
          @datetime
        end

        def expired?
          valid_until < @timezone.now
        end

        private 
        attr_reader :sym, :contract, :pkg, :interval, :readcache, :timezone

      end
    end
  end
end
