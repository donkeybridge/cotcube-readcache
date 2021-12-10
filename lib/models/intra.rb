module Cotcube
  class ReadCache
    module Entities
      class INTRA < BasicEntity

        VALIDITY = :interval
        INTERVAL = 30.minutes

        def initialize(
          readcache,
          asset: nil ,
          timezone: Cotcube::Helpers::CHICAGO
        )
          @sym =  Cotcube::Helpers.get_id_set(symbol: asset[..1])
          timezone = Time.find_zone(
            case @sym[:exchange].to_sym
            when :NYBOT, :NYMEX ; 'America/New_York'
            when :DTB           ; 'Europe/Berlin'
            else                ; 'America/Chicago'
            end
          )
          super
        end


        def update
          @sym ||= Cotcube::Helpers.get_id_set(symbol: asset[..1])

          other_tz = if %w[ NYBOT NYMEX ].include? @sym[:exchange]
                       'America/New_York'
                     elsif %w[ DTB ].include? @sym[:exchange]
                       'Europe/Berlin'
                     else
                       'America/Chicago'
                     end

          if payload.nil? or payload[:base].nil? or payload[:base].empty?
            raw    = Cotcube::Helpers::DataClient.new.get_historical(contract: asset, interval: :min30, duration: '30_D' )
            data   = JSON.parse(raw, symbolize_names: true) rescue { error: 1, msg: "Could not get data for contract #{asset}."}
            if data.empty?
              raw  = Cotcube::Helpers::DataClient.new.get_historical(contract: asset, interval: :min30, duration: '30_D' )
              data = JSON.parse(raw, symbolize_names: true) rescue { error: 1, msg: "Could not get data for contract #{asset}."}
            end
            unless data[:error].zero?
              puts "ERROR: #{data} ----> #{raw}" 
              data[:base] ||= []
            end
            base  = data[:base].
              map{ |z|
              z[:datetime] = timezone.parse(z[:time])
              %i[time created_at wap trades].each{|k| z.delete(k)}
              z
            }.select{|z| z[:high] } 
          else
            base    = payload[:base]
            raw     = Cotcube::Helpers::DataClient.new.get_historical(contract: asset, interval: :min30, duration: '1_D' )
            data    = JSON.parse(raw, symbolize_names: true) rescue { error: 1, msg: "Could not get data for contract #{asset}.", base: []}
            if data.empty?
              raw   = Cotcube::Helpers::DataClient.new.get_historical(contract: asset, interval: :min30, duration: '1_D' )
              data  = JSON.parse(raw, symbolize_names: true) rescue { error: 1, msg: "Could not get data for contract #{asset}.", base: []}
            end
            unless data[:error].zero?
              puts "ERROR: #{data} -----> #{raw}"
              data[:base] ||= []
            else
              new_base  = data[:base].
                map{ |z|
                z[:datetime] = DateTime.parse(z[:time])
                %i[time created_at wap trades].each{|k| z.delete(k)}
                z
              }.select{|z| z[:high] } rescue []
              new_base.each {|z| base << z if base.last[:datetime] < z[:datetime] }
            end
          end

          scaleBreaks = []
          brb   = readcache.deliver(:istencil, asset: asset[..1])[:payload]
          factor = (brb[1][:datetime] - brb[0][:datetime]).is_a?(Rational) ? 24.hours : 1
          brb.each_with_index.map{|z,i|
            next if i.zero?
            if (brb[i][:datetime] - brb[i-1][:datetime]) * factor > INTERVAL and brb[i][:datetime] > base.first[:datetime] and brb[i-1][:datetime] < base.last[:datetime]
              scaleBreaks << { startValue: brb[i-1][:datetime] + 0.5 * INTERVAL, endValue: brb[i][:datetime] - 0.5 * INTERVAL }
            end
          } unless base.empty?

          @payload = { base: base, breaks: scaleBreaks }
          super
        end

      end
    end
  end
end
