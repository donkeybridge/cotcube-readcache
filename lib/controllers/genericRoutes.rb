module Sinatra
  module GenericRoutes
    def self.registered(app)

      app.error 404 do 
        '404: Not found'
      end

      app.get '/:entity' do
        puts "Got params #{params}"
        force_update = params.keys.include? %w[update force]
        $cache.deliver(params['entity'], force_update: force_update).to_json
      end

      app.get '/:entity/:selector' do
        puts "Got params #{params}"
        force_update = params.keys.include? %w[update force]
        $cache.deliver(params['entity'], selector: params['selector'], force_update: force_update).to_json
      end

    end
  end
  register GenericRoutes
end
