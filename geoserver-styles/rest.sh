USER=admin
PASS=geoserver
GEOSERVER=http://localhost:8080/geoserver

for f in *.sld
do
	fshort=$(basename $f .sld)
	curl -u $USER:$PASS -XPOST -H "Content-type: text/xml" -d "<style><name>$fshort</name><filename>$f</filename></style>" $GEOSERVER/rest/styles
	echo ''
done

