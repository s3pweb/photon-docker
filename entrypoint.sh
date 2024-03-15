#!/bin/bash

trap ctrl_c INT
ctrl_c () {
    exit 1
}

set -eu

if [ $# -eq 0 ]; then
    echo "Usage: <command> [options]" >&2
    echo "where command is:" >&2

    echo "\t- import <country_code> [version]" >&2
    echo "\t\t- country_code is country code (eg. es, fr, ...) see https://download1.graphhopper.com/public/extracts/by-country-code/" >&2
    echo "\t\t\tor all to import planet" >&2
    echo "\t\t- version is optional prebuilt version (defaults to latest)" >&2

    echo "\t- server" >&2
    echo "\t\tstart photon server" >&2
    exit 1
fi

cmd="$1"
shift

# Import prebuilt photon ElasticSearch database
if [ "${cmd}" == "import" ]; then
	
	if [ ! -f /photon/photon_data/url ]; then
            rm -rf "/photon/photon_data/elasticsearch"
	fi

	country="$1"
	shift

	version="${1:-latest}"
	shift

	# Download elasticsearch index
	if [ ! -d "/photon/photon_data/elasticsearch" ]; then
	    echo "Downloading search index ${country} ${version}"

	    # Let graphhopper know where the traffic is coming from
	    USER_AGENT="docker: s3pweb/photon-geocoder"

	    url=""

	    if [ "${country}" == "all" ]; then
		if ! wget --quiet --user-agent="$USER_AGENT" -O - http://download1.graphhopper.com/public/|grep -q "photon-db-${version}.tar.bz2"; then
			echo "Unable to find ${url}" >&2
			exit 1
		fi

		url="http://download1.graphhopper.com/public/photon-db-${version}.tar.bz2"
	    else
		if ! wget --quiet --user-agent="$USER_AGENT" -O - http://download1.graphhopper.com/public/extracts/by-country-code/${country}/|grep -q "photon-db-${country}-${version}.tar.bz2"; then
			echo "Unable to find ${url}" >&2
			exit 1
		fi

		url="http://download1.graphhopper.com/public/extracts/by-country-code/${country}/photon-db-${country}-${version}.tar.bz2"
	    fi

	    echo "found ${url}"

	    wget --user-agent="$USER_AGENT" -O - ${url} | bzip2 -cd | tar x

	    echo "${url}" > /photon/photon_data/url

	    echo "${country}" > /photon/photon_data/country
	    echo "${version}" > /photon/photon_data/version
	fi

fi

# Start photon if elastic index exists
if [ "${cmd}" == "server" ]; then

	if [ -d "/photon/photon_data/elasticsearch" ]; then
	    echo "Start photon"
	    java -jar photon.jar $@
	else
	    echo "Could not start photon, the search index could not be found" >&2
	    exit 1
	fi

fi

