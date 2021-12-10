module Cotcube
  class ReadCache
    module Entities
      class EODS < BasicEntity

        VALIDITY = :day

        def update
          liquid_contracts_by_oi  = Cotcube::Bardata.provide_eods(threshold: 0.10, contracts_only: false, filter: :oi_part)
          liquid_contracts_by_vol = Cotcube::Bardata.provide_eods(threshold: 0.10, contracts_only: false, filter: :volume_part)
          @payload = (liquid_contracts_by_oi + liquid_contracts_by_vol).sort_by{|z| z[:contract]}.uniq
          super
        end

      end
    end
  end
end
