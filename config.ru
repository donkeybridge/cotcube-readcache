require 'rack'
require 'bundler'
Bundler.require

require_relative './app'
use Rack::Deflater

run CotcubeReadCache
