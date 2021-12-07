module Cotcube
  class ReadCache
    module Helpers
      class EODS

        def initialize(
          readcache,                               # backreference to the caller
          timezone: Cotcube::Helpers::CHICAGO
        )
          @readcache = readcache
          @timezone  = timezone
          update
        end

        def update
          @datetime = @timezone.now
          liquid_contracts_by_oi  = Cotcube::Bardata.provide_eods(threshold: 0.10, contracts_only: false, filter: :oi_part)
          liquid_contracts_by_vol = Cotcube::Bardata.provide_eods(threshold: 0.10, contracts_only: false, filter: :volume_part)
          @liquid_contracts = (liquid_contracts_by_oi + liquid_contracts_by_vol).sort_by{|z| z[:contract]}.uniq
        end

        def payload
          liquid_contracts
        end

        def valid_until
          @until ||= readcache.next_eod
        end

        def modified_at
          @datetime
        end

        def expired?
          valid_until < @timezone.now
        end

        private
        attr_reader :datetime, :timezone, :readcache, :liquid_contracts

      end
    end
  end
end
