module Cotcube
  class ReadCache
    module Entities
      class BasicEntity

        PERSISTANCE_STORE = '/var/cotcube/readcache'
        VALIDITY = :error

        def store_name
          @key ||= 
          "#{PERSISTANCE_STORE
         }/#{self.class.to_s.downcase.split(':').last
          }#{asset.nil? ? '' : "_#{asset.to_s.upcase}"}.json"
        end

        def initialize(
          readcache, 
          asset: nil ,
          timezone: Cotcube::Helpers::CHICAGO
        )
          @asset     = asset 
          @readcache = readcache
          @timezone  = timezone
          if File.exists?(store_name)
            data = JSON.parse(File.read(store_name), symbolize_names: true) rescue nil
            unless data.nil? 
              @payload  = Cotcube::Helpers.deep_decode_datetime(data[:payload], zone: timezone)
              @modified = timezone.parse(data[:modified])
              @until    = timezone.parse(data[:valid_until])
              @asset    = data[:asset]
            else
              puts "ERROR reading #{store_name}."
            end
          end
          update if payload.nil? or expired?
        end

        def update
          @until    = nil
          @modified = timezone.now
          dump
        end

        def dump
          File.write(store_name, JSON.dump( {
            modified:    modified,
            valid_until: valid_until,
            asset:       asset,
            payload:     payload
          } ) )
        end


        def valid_until
          @until ||= readcache.next_end_of(self.class::VALIDITY, asset)
        end

        def expired?
          valid_until < timezone.now
        end

        attr_reader :payload, :asset, :modified
        private
        attr_reader :until, :timezone, :readcache


      end
    end
  end
end
