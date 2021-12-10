module Cotcube
  class ReadCache
    module Entities
      class CONTINUOUS < BasicEntity

        VALIDITY = :day

        def update
          continuous = Cotcube::Bardata.continuous_table(symbol: asset, short: false)
          front      = continuous.sort_by{|z| z[:until_end].negative? ? z[:until_end] + 365 : z[:until_end] }[..1]
          front      = [ front.first ] unless front.first[:until_end] <= 3
          @payload   = { front: front.map{|z| z[:contract] }, continuous: continuous }
          super
        end

      end
    end
  end
end
