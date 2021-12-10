module Sinatra
  module GenericRoutes
    def self.registered(app)

      app.error 404 do 
        '404: Not found'
      end

      app.get '/:entity' do
        puts "#{DateTime.now.strftime('%Y-%m-%d %H:%M:S')}: Got params #{params}"
        force_update = params.keys.include? %w[update force]
        $cache.deliver(params['entity'], force_update: force_update).to_json
      end

      app.get '/:entity/:asset' do
        puts "#{DateTime.now.strftime('%Y-%m-%d %H:%M:S')}: Got params #{params}"
        force_update = params.keys.include? %w[update force]
        $cache.deliver(params['entity'], asset: params['asset'], force_update: force_update).to_json
      end

    end
  end
  register GenericRoutes
end
