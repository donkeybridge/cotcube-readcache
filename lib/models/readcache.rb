# require 'active_support/core_ext/time'
# require 'active_support/core_ext/numeric'


module Cotcube
  class ReadCache

    # the readcache is expected to serve the following entities with according validity periods
    #

    VALID_ENTITIES = { 
      # symbols are a list of supported symbols within the application, consisting of the main future assets as well as corresponding micro futures
      symbols:   { name: 'symbols',   maxage: 1.week,     until: :eow,   selector: 0 },

      # the cotdata is specific for each asset (based on the main future), and contains signal information
      cotdata:   { name: 'cotdata',   maxage: 1.week,     until: :eow,   selector: 2 },

      # breakfast contains a list of contracts (the front month for each asset), that also contains signal information
      breakfast: { name: 'breakfast', maxage: 1.day,      until: :eod,   selector: 0 },

      # the stencil is a continuous business days, that put everyday without weekends and (american) holidays onto an x-axis,
      #   where the current business day (CBD) == 0, past x grow und future x go negative
      #   if applicable, selector could turn to '2', containing the country hence pertaining the exchange holidays
      stencil:   { name: 'stencil',   maxage: 1.day,      until: :eod,   selector: 0 },

      # for (basically) each contract, daily holds daily bars
      daily:     { name: 'daily',     maxage: 1.day,      until: :eod,   selector: 5 },

      # for (basically) each contract, these are swaps found on eod run based on daily bars
      swaps:     { name: 'swaps',     maxage: 1.day,      until: :eod,   selector: 5 },

      # istencil is a continuous of intraday intervals (of 30,minutes), that skip maintenance periods, weekends and (american) holidays
      # there is a translation from asset to a more generic set, as istencils are based on shiftsets shared among several assets
      # also notable is the :full stencil, which is the base for iswaps
      istencil:  { name: 'istencil',  maxage: 30.minutes, until: :intra, selector: 2, init: lambda{|z| { asset: z, interval: 30.minutes } }  },

      # for each contract, intra holds intraday bars on the given interval, defaulting to 30.minutes (other are untested)
      intra:     { name: 'intra',     maxage: 30.minutes, until: :intra, selector: 5 },

      # for each contract, these are swaps found on intraday runs based on #interval bars
      iswaps:    { name: 'iswaps',    maxage: 30.minutes, until: :intra, selector: 5 },

      # for inspection, the keys the readcache holds itself
      keys:      { name: 'keys',      maxage: 30.minutes, until: :intra, selector: 0 }
    }

    VALIDATE_KLASS = %i[ payload valid_until expired? update created_at ]

    attr_reader :cache

    def initialize
      @cache= {}
      @monitor=Monitor.new
      deliver :stencil
      deliver :symbols
    end

    def deliver(entity, selector: nil)
      warnings = [] 
      # a bunch of validators
      return { error: 1, msg: "ArgumentError: entity must be a string or Symbol"   } unless %w[ String Symbol          ].include? entity.class.to_s
      return { error: 1, msg: "ArgumentError: selector must be a string or symbol" } unless %w[ String Symbol NilClass ].include? selector.class.to_s
      entity = entity.to_s.downcase.to_sym

      return { error: 1, msg: "ArgumentError: unknown entity, must be in #{VALID_ENTITIES.keys}" }  unless VALID_ENTITIES.keys.include? entity
      return { error: 1, msg: "ArgumentError: '#{entity}' MUST not contain a 'selector'." } if VALID_ENTITIES[entity][:selector].zero? and selector

      if VALID_ENTITIES[entity][:selector].positive? and VALID_ENTITIES[entity][:selector] != (selector.length rescue 0)
        return { error: 1, msg: "ArgumentError: Wrong or missing selector '#{selector}' for '#{entity}', should be of length"\
                 " #{VALID_ENTITIES[entity][:selector]}." } 
      end

      cache_key = selector.nil? ?  "#{entity.to_s}": "#{entity.to_s}_#{selector.to_s.upcase}" 
      klass = "Cotcube::ReadCache::Helpers::#{entity.to_s.upcase}"
      if entity == :istencil
        orig_selector = selector
        selector = Object.const_get(klass).set_selected(orig_selector)
        return { error: 1, msg: "ArgumentError: unknown selector '#{selector}' for entity '#{entity}'." } if selector == :error
        cache_key = "#{entity.to_s}_#{selector.to_s}"
      end
      if cache[cache_key].nil?
        monitor.synchronize do
          #                        'ReadCache::Helpers::SYMBOLS'      'ReadCache::Helper::ISTENCIL.new( { asset: :full } )
          obj   = selector.nil? ?  Object.const_get(klass).new(self) : Object.const_get(klass).new(self, VALID_ENTITIES[entity][:init].call(selector))
          lacking_methods = [] 
          VALIDATE_KLASS.each do |method| 
            lacking_methods << method unless obj.respond_to? method
          end
          return { error: 2, msg: "RuntimeError: '#{klass}' does not implement #{lacking_methods}." } unless lacking_methods.empty?
          cache[cache_key] = { obj: obj, monitor: Monitor.new, modified: Cotcube::Helpers::CHICAGO.now }
        end
      elsif cache[cache_key][:obj].expired?
        cache[cache_key][:monitor].synchronize do
          if cache[cache_key][:obj].expired?
            cache[cache_key][:monitor].update
          end
        end
      end
      # TODO: Set http cache-control according to :valid_until

      response = { error:         0,
                   warnings:      warnings,
                   created_at:    cache[cache_key][:obj].created_at,
                   valid_until:   cache[cache_key][:obj].valid_until,
                   payload:       cache[cache_key][:obj].payload
      }
    end

    private

    attr_accessor :monitor

  end
end
