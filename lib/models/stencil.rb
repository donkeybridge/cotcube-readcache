module Cotcube
  class ReadCache
    module Entities
      class STENCIL < BasicEntity

        VALIDITY = :day

        def update
          @stencil = Cotcube::Level::EOD_Stencil.new(swap_type: :full, timezone: timezone, interval: :daily)
          @payload = stencil.base.select{|z| z[:x] > -6 and z[:x] < 1500 }
          super
        end

        def index(i=0)
          stencil.index(i)
        end

        private
        attr_reader :stencil

      end
    end
  end
end
