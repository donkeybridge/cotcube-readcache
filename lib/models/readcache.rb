module Cotcube
  class ReadCache

    # the readcache is expected to serve the following entities with according validity periods
    #
    VALID_ENTITIES = { 
      # symbols are a list of supported symbols within the application, consisting of the main future assets as well as corresponding micro futures
      symbols:   { name: 'symbols',   maxage: 1.week,     until: :eow,   asset: 0 },

      #
      eods:      { name: 'eods',      maxage: 1.day,      until: :eod,   asset: 0 },

      #
      continuous: { name: 'continuous', maxage: 1.day,    until: :eod,   asset: 2, init: lambda{|z| { asset: z} } },

      # the cotdata is specific for each asset (based on the main future), and contains signal information
      cotdata:   { name: 'cotdata',   maxage: 1.week,     until: :eow,   asset: 2 },

      # breakfast contains a list of contracts (the front month for each asset), that also contains signal information
      breakfast: { name: 'breakfast', maxage: 1.day,      until: :eod,   asset: 0 },

      # the stencil is a continuous business days, that put everyday without weekends and (american) holidays onto an x-axis,
      #   where the current business day (CBD) == 0, past x grow und future x go negative
      #   if applicable, asset could turn to '2', containing the country hence pertaining the exchange holidays
      stencil:   { name: 'stencil',   maxage: 1.day,      until: :eod,   asset: 0 },

      # for (basically) each contract, daily holds daily bars
      daily:     { name: 'daily',     maxage: 1.day,      until: :eod,   asset: 5, init: lambda{|z| { asset: z } } },

      # for (basically) each contract, these are swaps found on eod run based on daily bars
      swaps:     { name: 'swaps',     maxage: 1.day,      until: :eod,   asset: 5 },

      # istencil is a continuous of intraday intervals (of 30,minutes), that skip maintenance periods, weekends and (american) holidays
      # there is a translation from asset to a more generic set, as istencils are based on shiftsets shared among several assets
      # also notable is the :full stencil, which is the base for iswaps
      istencil:  { name: 'istencil',  maxage: 30.minutes, until: :intra, asset: 2, init: lambda{|z| { asset: z } }  },

      # for each contract, intra holds intraday bars on the given interval, defaulting to 30.minutes (other are untested)
      intra:     { name: 'intra',     maxage: 30.minutes, until: :intra, asset: 5, init: lambda{|z| { asset: z } } },

      # for each contract, these are swaps found on intraday runs based on #interval bars
      iswaps:    { name: 'iswaps',    maxage: 30.minutes, until: :intra, asset: 5 },

      # for inspection, the keys the readcache holds itself
      keys:      { name: 'keys',      maxage: 30.minutes, until: :intra, asset: 0 }
    }

    VALIDATE_KLASS = %i[ payload valid_until expired? update modified ]

    attr_reader :cache

    def initialize
      @cache= {}
      @monitor=Monitor.new
      deliver :istencil, asset: :AA
      deliver :stencil
      deliver :symbols
    end

    def deliver(entity, asset: nil, force_update: false)
      warnings = [] 
      # a bunch of validators
      return { error: 1, msg: "ArgumentError: entity must be a string or Symbol" } unless %w[ String Symbol          ].include? entity.class.to_s
      return { error: 1, msg: "ArgumentError: asset  must be a string or symbol" } unless %w[ String Symbol NilClass ].include? asset.class.to_s
      entity = entity.to_s.downcase.to_sym

      return { error: 1, msg: "ArgumentError: unknown entity, must be in #{VALID_ENTITIES.keys}" }  unless VALID_ENTITIES.keys.include? entity

      if VALID_ENTITIES[entity][:asset].zero? and asset
        warnings << "ArgumentError: '#{entity}' MUST not contain a 'asset' (got '#{asset}'. Ignoring asset."
        asset = nil
      end

      if VALID_ENTITIES[entity][:asset].positive? and VALID_ENTITIES[entity][:asset] != (asset.length rescue 0)
        return { error: 1, msg: "ArgumentError: Wrong or missing asset '#{asset}' for '#{entity}', should be of length"\
                 " #{VALID_ENTITIES[entity][:asset]}." }
      end

      cache_key = asset.nil? ?  "#{entity.to_s}": "#{entity.to_s}_#{asset.to_s.upcase}"
      klass = "Cotcube::ReadCache::Entities::#{entity.to_s.upcase}"
      if entity == :istencil
        orig_asset = asset
        asset = Object.const_get(klass).set_selected(orig_asset)
        return { error: 1, msg: "ArgumentError: unknown asset '#{orig_asset}' for entity '#{entity}'." } if asset == :error
        cache_key = "#{entity.to_s}_#{asset.to_s}"
      end
      if cache[cache_key].nil?
        monitor.synchronize do
          obj   = asset.nil? ?  Object.const_get(klass).new(self) : Object.const_get(klass).new(self, VALID_ENTITIES[entity][:init].call(asset))
          lacking_methods = [] 
          VALIDATE_KLASS.each do |method| 
            lacking_methods << method unless obj.respond_to? method
          end
          return { error: 2, msg: "RuntimeError: '#{klass}' does not implement #{lacking_methods}." } unless lacking_methods.empty?
          cache[cache_key] = { obj: obj, monitor: Monitor.new, modified: Cotcube::Helpers::CHICAGO.now }
        end
      elsif force_update || cache[cache_key][:obj].expired?
        cache[cache_key][:monitor].synchronize do
          cache[cache_key][:obj].update if force_update || cache[cache_key][:obj].expired?
        end
      end
      # TODO: Set http cache-control according to :valid_until

      respond_with(cache_key, warnings)

    end

    def respond_with(cache_key, warnings = [])
      { error:         0,
        warnings:      warnings,
        modified:      cache[cache_key][:obj].modified,
        valid_until:   cache[cache_key][:obj].valid_until,
        payload:       cache[cache_key][:obj].payload
      }
    end

    def next_eop(contract=:AA); next_end_of(:period, contract); end
    def next_eod(contract=:AA); next_end_of(:day,    contract); end
    def next_eow(contract=:AA); next_end_of(:week,   contract); end

    def next_end_of(interval, contract=nil)
      contract ||= :AA
      appropriate_intervals = %i[ day interval period week month quarter year ]
      raise ArgumentError, "inappropriate interval #{interval}, please choose from #{appropriate_intervals}." unless appropriate_intervals.include? interval

      seg = Cotcube::ReadCache::Entities::ISTENCIL.set_selected(contract)
      deliver( :istencil, asset: contract[..1]) if cache["istencil_#{seg}"].nil?

      cache["istencil_#{seg}"][:obj].send(
        case interval
        when :day;               :next_eod
        when :interval, :period; :next_eop
        when :week;              :next_eow
        else;                    raise "#{interval} not yet implemented"
        end
      )
    end


    private

    attr_accessor :monitor

  end
end
