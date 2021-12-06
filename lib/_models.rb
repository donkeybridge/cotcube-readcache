
Dir["#{Dir.pwd}/lib/models/*.rb"].each do |file|
  require file
end
