#!/bin/bash

#cat <<EOF 
#***   Tietoa OSM:n päivitysajosta ***
#
# Geosever:illä toteutettu OSM:n Suomen alueen wms/wmts/wfs-palvelu.  
# OSM-aineisto päivitetään automaattisesti ajoitettuna lauantaisin.
#
# Tässä on menossa ko. paivitysajo, jossa
#  - haetaan uusi suomen OSM aineisto palvelimelta download.geofabrik.de
#  - viedään se PostGIS kantaan osm_finland $SRID_DST koordinaattijärjestelmässä
#  - päitetään geoserver:in wms-cache aineiston osalta
#
# Seuraavassa vähän tietoa päivitysajon kulusta.  
#EOF

DB_HOST="localhost"
DB_PORT=5432
DB_USER=<db user>
DB_DATABASE=osm_finland
DB_SCHEMA=public

SRID_SRC=4326
SRID_DST=3879

X_MIN=25450000
X_MAX=25530000
Y_MIN=6630000
Y_MAX=6750000

echo -e "\nosm-update alkoi:" $(date)

### 2) Tyhjennä tmp ja siirry sinne.  

rm -fr /tmp/osm

IFS=$'\n'
for l in $(df -m /tmp); do
 echo "---" $l
done
mkdir /tmp/osm
cd   /tmp/osm

### 3) Haetaan OSM:n .zip ja .osm.pbf
wget -q http://download.geofabrik.de/europe/finland-latest-free.shp.zip
wget -q http://download.geofabrik.de/europe/finland-latest.osm.pbf

### 4) pura zip
unzip -qq finland-latest-free.shp.zip 

#Natural: tree, beach, cave, cliff, peak, spring. Not used now.
rm gis_osm_natural*

#Places_a: islands, farms, etc, Not used now.
rm gis_osm_places_a*

#Not used.
rm gis_osm_water_a*

echo 'rename, approximate clip and reproj'
ogr2ogr -spat $X_MIN $Y_MIN $X_MAX $Y_MAX -spat_srs EPSG:$SRID_DST buildings.shp gis_osm_buildings_a_free_1.shp -lco ENCODING=UTF-8
ogr2ogr -spat $X_MIN $Y_MIN $X_MAX $Y_MAX -spat_srs EPSG:$SRID_DST landuse.shp gis_osm_landuse_a_free_1.shp -lco ENCODING=UTF-8
ogr2ogr -spat $X_MIN $Y_MIN $X_MAX $Y_MAX -spat_srs EPSG:$SRID_DST places.shp gis_osm_places_free_1.shp -lco ENCODING=UTF-8
ogr2ogr -spat $X_MIN $Y_MIN $X_MAX $Y_MAX -spat_srs EPSG:$SRID_DST pofw.shp gis_osm_pofw_free_1.shp -lco ENCODING=UTF-8
ogr2ogr -spat $X_MIN $Y_MIN $X_MAX $Y_MAX -spat_srs EPSG:$SRID_DST pofw_a.shp gis_osm_pofw_a_free_1.shp -lco ENCODING=UTF-8
ogr2ogr -spat $X_MIN $Y_MIN $X_MAX $Y_MAX -spat_srs EPSG:$SRID_DST points.shp gis_osm_pois_free_1.shp -lco ENCODING=UTF-8
ogr2ogr -spat $X_MIN $Y_MIN $X_MAX $Y_MAX -spat_srs EPSG:$SRID_DST points_a.shp gis_osm_pois_a_free_1.shp -lco ENCODING=UTF-8
ogr2ogr -spat $X_MIN $Y_MIN $X_MAX $Y_MAX -spat_srs EPSG:$SRID_DST railways.shp gis_osm_railways_free_1.shp -lco ENCODING=UTF-8
ogr2ogr -spat $X_MIN $Y_MIN $X_MAX $Y_MAX -spat_srs EPSG:$SRID_DST roads.shp gis_osm_roads_free_1.shp -lco ENCODING=UTF-8
ogr2ogr -spat $X_MIN $Y_MIN $X_MAX $Y_MAX -spat_srs EPSG:$SRID_DST traffic.shp gis_osm_traffic_free_1.shp -lco ENCODING=UTF-8
ogr2ogr -spat $X_MIN $Y_MIN $X_MAX $Y_MAX -spat_srs EPSG:$SRID_DST traffic_a.shp gis_osm_traffic_a_free_1.shp -lco ENCODING=UTF-8
ogr2ogr -spat $X_MIN $Y_MIN $X_MAX $Y_MAX -spat_srs EPSG:$SRID_DST transport.shp gis_osm_transport_free_1.shp -lco ENCODING=UTF-8
ogr2ogr -spat $X_MIN $Y_MIN $X_MAX $Y_MAX -spat_srs EPSG:$SRID_DST transport_a.shp gis_osm_transport_a_free_1.shp -lco ENCODING=UTF-8
ogr2ogr -spat $X_MIN $Y_MIN $X_MAX $Y_MAX -spat_srs EPSG:$SRID_DST waterways.shp gis_osm_waterways_free_1.shp -lco ENCODING=UTF-8

# Remove original files
rm gis_osm_*

echo 'rename fclass to type'
# rename fclass column to type (all layers except buildings which already has a field called type))
#ogrinfo buildings.shp -q -sql "alter table buildings rename column fclass to type"
ogrinfo landuse.shp -q -sql "alter table landuse rename column fclass to type"
#ogrinfo natural_a.shp -q -sql "alter table natural_a rename column fclass to type"
#ogrinfo natural.shp -q -sql "alter table natural rename column fclass to type"
ogrinfo places.shp -q -sql "alter table places rename column fclass to type"
#ogrinfo places_a.shp -q -sql "alter table places_a rename column fclass to type"
ogrinfo pofw.shp -q -sql "alter table pofw rename column fclass to type"
ogrinfo pofw_a.shp -q -sql "alter table pofw_a rename column fclass to type"
ogrinfo points.shp -q -sql "alter table points rename column fclass to type"
ogrinfo points_a.shp -q -sql "alter table points_a rename column fclass to type"
ogrinfo railways.shp -q -sql "alter table railways rename column fclass to type"
ogrinfo roads.shp -q -sql "alter table roads rename column fclass to type"
ogrinfo traffic.shp -q -sql "alter table traffic rename column fclass to type"
ogrinfo traffic_a.shp -q -sql "alter table traffic_a rename column fclass to type"
ogrinfo transport.shp -q -sql "alter table transport rename column fclass to type"
ogrinfo transport_a.shp -q -sql "alter table transport_a rename column fclass to type"
#ogrinfo water.shp -q -sql "alter table water rename column fclass to type"
ogrinfo waterways.shp -q -sql "alter table waterways rename column fclass to type"

# TRANSPORT
echo 'transport'
# copy stops to Points layer
ogr2ogr -f "ESRI Shapefile" -append -update -where "type='railway_station' OR type='railway_halt' OR type='tram_stop' OR type='bus_stop' OR type='bus_station' OR type='ferry_terminal' OR type='airport' OR type='taxi_rank'" points.shp transport.shp

ogr2ogr -f "ESRI Shapefile" -append -update -where "type='railway_station' OR type='railway_halt' OR type='tram_stop' OR type='bus_stop' OR type='bus_station' OR type='ferry_terminal' OR type='airport' OR type='taxi_rank'" points_a.shp transport_a.shp

# move Fuel stations to Points layer
ogr2ogr -f "ESRI Shapefile" -append -update -where "type='fuel'" points.shp traffic.shp 
ogr2ogr -f "ESRI Shapefile" -append -update -where "type='fuel'" points_a.shp traffic_a.shp 

# POFW
echo 'powf'
# change type to 'place_of_worship'
ogrinfo pofw.shp -dialect SQLITE -q -sql "update pofw set type='place_of_worship'"
ogrinfo pofw_a.shp -dialect SQLITE -q -sql "update pofw_a set type='place_of_worship'"

# copy elements to pois layer 
ogr2ogr -f "ESRI Shapefile" -append -update points.shp pofw.shp
ogr2ogr -f "ESRI Shapefile" -append -update points_a.shp pofw_a.shp

# Remove layers not used as tables
rm traffic*
rm transport*
rm pofw*

### 4A)Add lakes and municipality borders from .pbf file. Drop unnecessary column from municipalities.
#Water includes islands of lakes in some strange way, so they get also colored
#Landuse has less protected areas like this way, so also kept in old style.
ogr2ogr -spat $X_MIN $Y_MIN $X_MAX $Y_MAX -spat_srs EPSG:$SRID_DST -where "natural like 'water'" lakes.shp finland-latest.osm.pbf multipolygons -lco ENCODING=UTF-8
#ogr2ogr -where "leisure='nature_reserve' or boundary LIKE 'national_park%' OR boundary='protected_area'" protected.shp finland-latest.osm.pbf multipolygons -lco ENCODING=UTF-8

ogr2ogr -where "name IN ('Helsinki', 'Espoo', 'Vantaa', 'Kauniainen', 'Hyvinkää', 'Järvenpää', 'Kerava', 'Kirkkonummi', 'Nurmijärvi', 'Sipoo', 'Tuusula', 'Vihti', 'Mäntsälä', 'Pornainen') AND admin_level='8'" municipalities.shp finland-latest.osm.pbf multipolygons -lco ENCODING=UTF-8
ogrinfo municipalities.shp -sql "alter table municipalities drop column other_tags"

### 5) muuta shp:t  sql:ksi ja laataa kantaan
echo -e "\n*** Ladataan seuraavat layer:it osm_finland kantaan:"
for f in *.shp 
do 
 echo -e "\n---" $f
 fshort=$(basename $f .shp)
 shp2pgsql -d -D -I -s $SRID_SRC:$SRID_DST $f $DB_SCHEMA.$fshort | psql -q -h $DB_HOST -p $DB_PORT -U $DB_USER -d $DB_DATABASE 1>/dev/null
done 

echo -e "\n*** Poistetaan Helsingin seudun kuntien ulkopuoliset"
psql -q -h $DB_HOST -p $DB_PORT -U $DB_USER -d $DB_DATABASE -c "CREATE TABLE IF NOT EXISTS municipalities_union AS SELECT ST_Union(geom) AS geom FROM municipalities;"
psql -q -h $DB_HOST -p $DB_PORT -U $DB_USER -d $DB_DATABASE -c "CREATE INDEX ON municipalities_union USING GIST (geom);"
for f in *.shp
do
  fshort=$(basename $f .shp)
  psql -q -h $DB_HOST -p $DB_PORT -U $DB_USER -d $DB_DATABASE -c "DELETE FROM $fshort WHERE gid IN (SELECT gid FROM $fshort a JOIN municipalities_union b ON NOT ST_Intersects(a.geom, b.geom));"
done
psql -q -h $DB_HOST -p $DB_PORT -U $DB_USER -d $DB_DATABASE -c "DROP TABLE municipalities_union"


echo -e "\n*** Generoidaan indexit"

psql -q -h $DB_HOST -p $DB_PORT -U $DB_USER -d $DB_DATABASE -c "CREATE INDEX ON roads (type)"
psql -q -h $DB_HOST -p $DB_PORT -U $DB_USER -d $DB_DATABASE -c "CREATE INDEX ON landuse (type)"
#psql -q -h $DB_HOST -p $DB_PORT -U $DB_USER -d $DB_DATABASE -c "CREATE INDEX ON nature (type)"
psql -q -h $DB_HOST -p $DB_PORT -U $DB_USER -d $DB_DATABASE -c "CREATE INDEX ON points (type)"
psql -q -h $DB_HOST -p $DB_PORT -U $DB_USER -d $DB_DATABASE -c "CREATE INDEX ON points_a (type)"
psql -q -h $DB_HOST -p $DB_PORT -U $DB_USER -d $DB_DATABASE -c "CREATE INDEX ON places (type)"
psql -q -h $DB_HOST -p $DB_PORT -U $DB_USER -d $DB_DATABASE -c "CREATE INDEX ON places (population)"
psql -q -h $DB_HOST -p $DB_PORT -U $DB_USER -d $DB_DATABASE -c "CREATE INDEX ON railways (type)"
psql -q -h $DB_HOST -p $DB_PORT -U $DB_USER -d $DB_DATABASE -c "CREATE INDEX ON waterways (type)"
### 6) Käynnistä tomcat/geoserver?  Katso yllä onko pysäytetty.

### 7) Päivitä geoserver:in cache

osm-cache-seed   # tämä on omana scriptinä, jos tarvitaan ajaa erikseen

cat <<EOF

Jos ed. taulukon rivit eivät ole tyhjiä, niin cache:n generointi pitäisi olla ok.
EOF
cat << EOF
That's all!  
Jos edellä oli virheilmoituksia, niin pitäsi kai tehdä jotain ?
EOF

echo -e "\nosm-update loppui:" $(date)




