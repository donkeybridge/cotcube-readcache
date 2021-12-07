module Cotcube
  class ReadCache
    module Helpers
      class SYMBOLS

        def initialize(
          readcache,
          timezone: Cotcube::Helpers::CHICAGO,
          datetime: Cotcube::Helpers::CHICAGO.now  # meant for testing purposes, dont use in production
        )
          @datetime = datetime
          @timezone = timezone
          @symbols =  Cotcube::Helpers.symbols + Cotcube::Helpers.micros
        end

        def update
          @datetime = @timezone.now
          @until    = @datetime + 7.days
          @symbols =  Cotcube::Helpers.symbols + Cotcube::Helpers.micros
        end

        def valid_until
          # TODO: Implement proper @until based on eod_stencil
          @until ||= @timezone.now + 7.days
        end

        def payload;                       @symbols; end
        def expired?  ; valid_until < @timezone.now; end
        def modified_at;                   @datetime; end

      end
    end
  end
end
