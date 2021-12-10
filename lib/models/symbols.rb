module Cotcube
  class ReadCache
    module Entities
      class SYMBOLS < BasicEntity

        VALIDITY = :week

        def update
          @payload =  Cotcube::Helpers.symbols + Cotcube::Helpers.micros
          super
        end

      end
    end
  end
end
