require "#{Dir.pwd}/lib/models/readcache"
require "#{Dir.pwd}/lib/models/basic_entity"

Dir["#{Dir.pwd}/lib/models/*.rb"].each do |file|
  require file
end
