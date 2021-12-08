module Cotcube
  class ReadCache
    module Helpers
      class CONTINUOUS

        def initialize(
          readcache,                               # backreference to the caller
          asset: ,
          timezone: Cotcube::Helpers::CHICAGO
        )
          @readcache = readcache
          @timezone  = timezone
          @asset     = asset
          update
        end

        def update
          @datetime = timezone.now
          @until    = nil
          @continuous  = Cotcube::Bardata.continuous_table(symbol: asset, short: false)
          @front    = continuous.sort_by{|z| z[:until_end].negative? ? z[:until_end] + 365 : z[:until_end] }[..1]
          @front    = [ front.first ] unless front.first[:until_end] >= 3
        end

        def valid_until
          @until ||= @readcache.next_eod(asset)
        end

        def modified_at
          datetime
        end

        def payload
          { front: front.map{|z| z[:contract] }, table: continuous }
        end

        def expired?
          valid_until < timezone.now
        end

        private
        attr_reader :datetime, :timezone, :readcache, :continuous, :asset, :front


      end
    end
  end
end
