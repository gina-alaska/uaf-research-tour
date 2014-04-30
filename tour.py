#!/usr/bin/env python

import yaml
import simplekml

io = open('tour.yaml', 'r')
tour = yaml.load(io)

kml = simplekml.Kml(name='UAF Research Tour', open=1)

kmltour = kml.newgxtour(name="UAF Research Tour")
playlist = kmltour.newgxplaylist()


for location in tour:
  print "Looking at " + location['title']
  flyto = playlist.newgxflyto(gxduration=location.get('duration', 3))
  flyto.lookat.longitude = location['longitude']
  flyto.lookat.latitude = location['latitude']
  flyto.lookat.range = location['range']
  flyto.lookat.altitude = location.get('altitude',0)
  flyto.lookat.heading = location.get('heading', 0)
  flyto.lookat.tilt = location.get('tilt', 0)
  flyto.lookat.roll = location.get('roll', 0)

  wait = playlist.newgxwait(gxduration=location.get('wait', 3))

kml.save('uaf_research_tour.kml')
