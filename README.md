# osm-survey-jobs

A list and map of current possible survey jobs in Berlin can be seen [here](http://bbbike.de/cgi-bin/bbbikeleaflet.cgi?geojsonp_url=https%3A//eserte.github.io/osm-survey-jobs/osm-survey-jobs-berlin.bbbgeojsonp&zoom=11&lat=52.512042&lon=13.421173&bm=B&devel=1).

Current workflow (manually):

* Download open notes for a given area, e.g. for Berlin:

    wget 'https://api.openstreetmap.org/api/0.6/notes.json?bbox=13.051179,52.337621,13.764158,52.689878&limit=10000&closed=0' -O /tmp/notes-berlin.json

* Find potential "osm survey jobs" and dump them as a bbbike .bbd file:

    ./find-osm-survey-jobs.pl --debug /tmp/notes-berlin.json >| /tmp/osm-survey-jobs-berlin.bbd

* Convert this file into a geojson file usable for jsonp loading. Requires a checkout of https://github.com/eserte/bbbike in ~/src/bbbike:

    ~/src/bbbike/miscsrc/bbd2geojson -bbbgeojsonp /tmp/osm-survey-jobs-berlin.bbd >| /tmp/osm-survey-jobs-berlin.bbbgeojsonp

* Copy the generated .bbbgeojsonp file to a suitable webserver. If bbbike is running locally, then this can be done with:

    cp /tmp/osm-survey-jobs-berlin.bbbgeojsonp ~/src/bbbike/tmp/bbbgeojsonp/

* Load it:

    http://localhost/bbbike/cgi/bbbikeleaflet.cgi?geojsonp_url=/bbbike/tmp/bbbgeojsonp/osm-survey-jobs-berlin.bbbgeojsonp&zoom=11&lat=52.512042&lon=13.421173&bm=B
    http://bbbike.de/cgi-bin/bbbikeleaflet.cgi?geojsonp_url=/BBBike/tmp/bbbgeojsonp/osm-survey-jobs-berlin.bbbgeojsonp&zoom=11&lat=52.512042&lon=13.421173&bm=B

GitHub workflow:

* Trigger a build in https://github.com/eserte/osm-survey-jobs/actions/workflows/berlin.yml