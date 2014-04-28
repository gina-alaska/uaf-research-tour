require 'ruby_kml'
require 'csv'
require 'soda'

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

kml = KMLFile.new
folder = KML::Folder.new(name: "Airport locations")
style = KML::Style.new(
  id: "default",
  icon_style: KML::IconStyle.new(icon:
    KML::Icon.new(href: "http://maps.google.com/mapfiles/kml/paddle/red-circle-lv.png")
  )
)
kml.objects << style


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

results.each do |result|
  folder.features << KML::Placemark.new(
    name: result[2..3].join(", "),
    style_url: "#default",
    geometry: KML::Point.new(
      coordinates: {
        lat: result[6],
        lng: result[7]
      }
    )
)
end

opendata_results.each do |result|
  folder.features << KML::Placemark.new(
    name: result.locationid,
    style_url: "#default",
    geometry: KML::Point.new(
      coordinates: {
        lat: result.latitude.to_f,
        lng: -result.longitude.to_f
      }
    )
  )
end


kml.objects << folder
File.open("airport_locations.kml","w") do |file|
  file << kml.render
end
