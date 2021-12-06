require 'rack'
require 'bundler'
Bundler.require
require 'sinatra/base'
require 'active_support'
require 'active_support/core_ext/time'
require 'active_support/core_ext/numeric'

require_relative './app'
use Rack::Deflater

run CotcubeReadCache
