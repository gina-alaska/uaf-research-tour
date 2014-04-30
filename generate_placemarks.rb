require 'ruby_kml'
require 'yaml'

placemarks = YAML.load_file("placemarks.yml")

kml = KMLFile.new
document = KML::Document.new(name: "Airport locations")
style = KML::Style.new(
  id: "default",
  icon_style: KML::IconStyle.new(icon:
    KML::Icon.new(href: "http://maps.google.com/mapfiles/kml/paddle/red-circle-lv.png")
  )
)
document.styles << style


placemarks.each do |placemark|
  document.features << KML::Placemark.new(
    name: placemark['name'],
    style_url: "#default",
    geometry: KML::Point.new(
      coordinates:{
        lat: placemark['latitude'],
        lng: placemark['longitude']
      }
    )
  )
end

kml.objects << document

File.open("airport_locations.kml","w") do |file|
  file << kml.render
end
