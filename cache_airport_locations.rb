require 'csv'
require 'soda'
require 'yaml'

LIMIT=1000

def fetch_airports( code, filterfield, filter )
  client = SODA::Client.new({
    domain: 'opendata.socrata.com',
    app_token: ENV['SOCRATA_APP_TOKEN'],
    ignore_ssl: true
  })

  response = client.get(code)
  results = response.dup
  page = 0
  while response.count == 1000
    page +=1
    puts "Fetching page #{page}"
    response = client.get('rxrh-4cxm', {"$limit" => LIMIT, "$offset" => (page * LIMIT)})
    results << response
  end

  results.flatten!
  results.select{|row| filter.include?(row.send(filterfield))}
end

locations = CSV.new(File.open(ARGV[0], 'r'))
location_ids = locations.collect{|l| l.first.strip.upcase}.sort
data = CSV.new(File.open("airports.dat", 'r'))

puts "Looking for #{location_ids.count}"
results = data.select{|row| location_ids.include? row[4].upcase}
puts "Found #{results.count}"

found_ids = results.collect{|r| r[4]}
missing_ids = location_ids - found_ids
puts "Missing: #{missing_ids.join(",")}"
puts "Trying opendata.socrata.org..."

opendata_results = fetch_airports('rxrh-4cxm', :locationid, missing_ids)
puts "Found #{opendata_results.count}"
puts "Still missing #{(missing_ids - opendata_results.collect(&:locationid)).join(",")}"
puts "Generating KML..."

puts "Saving to local cache as YAML:"
final_results = []

results.each do |result|
  final_results << {
    "name" => result[2..3].join(", "),
    "latitude" => result[6].to_f,
    "longitude" => result[7].to_f
  }
end
opendata_results.each do |result|
  final_results << {
    "name" => result.locationid,
    "latitude" => result.latitude.to_f,
    "longitude" => -result.longitude.to_f
  }
end

final_results += YAML.load_file("additional_sites.yml")
File.open("placemarks.yml", "w") do |f|
  f << final_results.to_yaml
end
