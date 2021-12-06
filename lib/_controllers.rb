
Dir["#{Dir.pwd}/lib/controllers/*.rb"].each do |file|
  require file
end
