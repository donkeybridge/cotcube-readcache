require 'rack'

require_relative './app'
use Rack::Deflater

run CotcubeReadCache
