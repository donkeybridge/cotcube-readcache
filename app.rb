require 'bundler'
Bundler.require
require 'json'
require 'cotcube-helpers'
require 'cotcube-level'
require 'cotcube-bardata'
require_relative 'lib/_models'
require_relative 'lib/_controllers'

class CotcubeReadCache < Sinatra::Base

  %w[ Generic ].each do |part|
    register Object.const_get("Sinatra::#{part}Routes")
  end

  $cache = Cotcube::ReadCache.new

end

