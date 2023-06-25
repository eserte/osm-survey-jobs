# osm-survey-jobs

## Available osm-survey-jobs maps

Lists and maps of currently available survey jobs can be seen here:

* [Berlin](http://bbbike.de/cgi-bin/bbbikeleaflet.cgi?geojsonp_url=https%3A//eserte.github.io/osm-survey-jobs/osm-survey-jobs-berlin.bbbgeojsonp&bm=O&fl=1)

## Workflow to create maps:

* Define some local variables, e.g. for Berlin
```
    areaname=berlin
    areabbox=13.051179,52.337621,13.764158,52.689878
```
* Download open notes for the specified area:
```
    wget 'https://api.openstreetmap.org/api/0.6/notes.json?bbox='$areabbox'&limit=10000&closed=0' -O /tmp/notes-$areaname.json
```
* Find potential "osm survey jobs" and dump them as a bbbike .bbd file:
```
    ./find-osm-survey-jobs.pl --debug /tmp/notes-$areaname.json >| /tmp/osm-survey-jobs-$areaname.bbd
```
* Convert this file into a geojson file usable for jsonp loading. Requires a checkout of https://github.com/eserte/bbbike in ~/src/bbbike:
```
    PERL5LIB=$(pwd)/lib ~/src/bbbike/miscsrc/bbd2geojson -bbbgeojsonp -manipulatemodule GeoJSONFeatProps /tmp/osm-survey-jobs-$areaname.bbd >| /tmp/osm-survey-jobs-$areaname.bbbgeojsonp
```
* Copy the generated .bbbgeojsonp file to a suitable webserver. If bbbike is running locally, then this can be done with:
```
    cp /tmp/osm-survey-jobs-$areaname.bbbgeojsonp ~/src/bbbike/tmp/bbbgeojsonp/
```
* Load it:
  * http://localhost/bbbike/cgi/bbbikeleaflet.cgi?geojsonp_url=/bbbike/tmp/bbbgeojsonp/osm-survey-jobs-berlin.bbbgeojsonp&bm=O
  * http://bbbike.de/cgi-bin/bbbikeleaflet.cgi?geojsonp_url=/BBBike/tmp/bbbgeojsonp/osm-survey-jobs-berlin.bbbgeojsonp&bm=O

GitHub workflow:

* Trigger a build in https://github.com/eserte/osm-survey-jobs/actions/workflows/berlin.yml
