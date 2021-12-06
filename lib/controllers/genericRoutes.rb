module Sinatra
  module GenericRoutes
    def self.registered(app)

      app.error 404 do 
        '404: Not found'
      end

      app.get '/:entity' do
        puts "Got params #{params}"
        $cache.deliver(params['entity']).to_json
      end

      app.get '/:entity/:selector' do
        puts "Got params #{params}"
        $cache.deliver(params['entity'], selector: params['selector']).to_json
      end

    end
  end
  register GenericRoutes
end
