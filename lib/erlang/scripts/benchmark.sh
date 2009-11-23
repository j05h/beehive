#!/bin/sh

progdir=$(dirname $0)
progname=$(basename $0)
version="0.1"

print_usage() {
cat <<EOF
Usage: $progname options

Run benchmarking against the proxy

OPTIONS
	-t, --total	Total number of connections for each request
	-p, --proxy Proxy url
	-r, --raw Raw url
	-P, --port Port
	-h, --help	Show this screen
	
EOF
}

print_version() {
cat <<EOF
$progname $version

Copyright (C) 2009 Ari Lerner
EOF
}

run_comparison_graph() {
	echo "plot \
	  '/tmp/graph-proxy.data1' using 10 with lines title 'Proxy ($TOTAL/1)', \
	  '/tmp/graph-proxy.data2' using 10 with lines title 'Proxy ($TOTAL/25)', \
	  '/tmp/graph-proxy.data3' using 10 with lines title 'Proxy ($TOTAL/50)', \
	  '/tmp/graph-raw.data1' using 10 with lines title 'Raw ($TOTAL/1)', \
	  '/tmp/graph-raw.data2' using 10 with lines title 'Raw ($TOTAL/25)', \
	  '/tmp/graph-raw.data3' using 10 with lines title 'Raw ($TOTAL/50)'
	" >> $PLOT_OUTPUT_SCRIPT
	
	echo "Benchmarking..."
	REMOTE_URL="http://$PROXY_URL:$PORT$URL"
	echo "---- PROXY : $REMOTE_URL ----"
	echo "$TOTAL HTTP requests 1/3";
	$AB -n $TOTAL -g /tmp/graph-proxy.data1 $REMOTE_URL > /dev/null
	echo "$TOTAL HTTP requests 2/3 with 25 concurrent requests";
	$AB -n $TOTAL -c 25 -g /tmp/graph-proxy.data2 $REMOTE_URL > /dev/null
	echo "$TOTAL HTTP requests 3/3 with 50 concurrent requests";
	$AB -n $TOTAL -c 50 -g /tmp/graph-proxy.data3 $REMOTE_URL/$URL > /dev/null

	REMOTE_URL="http://$RAW_URL:$PORT$URL"
	echo "---- RAW : $REMOTE_URL ----"
	echo "$TOTAL HTTP requests 1/3";
	$AB -n $TOTAL -g /tmp/graph-raw.data1 $REMOTE_URL > /dev/null
	echo "$TOTAL HTTP requests 2/3 with 25 concurrent requests";
	$AB -n $TOTAL -c 25 -g /tmp/graph-raw.data2 $REMOTE_URL > /dev/null
	echo "$TOTAL HTTP requests 3/3 with 50 concurrent requests";
	$AB -n $TOTAL -c 50 -g /tmp/graph-raw.data3 $REMOTE_URL/$URL > /dev/null
}

run_proxy_graph() {
	echo "plot \
	  '/tmp/graph-proxy' using 10 with lines title 'Benchmark proxy ($TOTAL/$CONCURRENT)'
	" >> $PLOT_OUTPUT_SCRIPT
	
	echo "Benchmarking..."
	REMOTE_URL="http://$PROXY_URL:$PORT$URL"
	echo "---- PROXY : $REMOTE_URL ($TOTAL/$CONCURRENT) ----"
	$AB -n $TOTAL -c $CONCURRENT -g /tmp/graph-proxy $REMOTE_URL > /dev/null
}

# Defaults
AB=`which ab`
GNUPLOT=`which gnuplot`
PLOT_OUTPUT_SCRIPT="/tmp/plot_script"
TOTAL=1000
CONCURRENT=3
OUTPUT="graph"
VERBOSE=false
PORT=8080
NAME="test"
TYPE="comparison"
URL="/"

SHORTOPTS="ht:o:p:r:P:n:u:c:T:"
LONGOPTS="help,version,total,output,port,raw,proxy,name,url,concurrent,type"

if $(getopt -T >/dev/null 2>&1) ; [ $? = 4 ] ; then # New longopts getopt.
    OPTS=$(getopt -o $SHORTOPTS --long $LONGOPTS -n "$progname" -- "$@")
else # Old classic getopt.
    # Special handling for --help and --version on old getopt.
    case $1 in --help) print_usage ; exit 0 ;; esac
    case $1 in --version) print_version ; exit 0 ;; esac
    OPTS=$(getopt $SHORTOPTS "$@")
fi

if [ $? -ne 0 ]; then
    echo "'$progname --help' for more information" 1>&2
    exit 1
fi

eval set -- "$OPTS"
while [ $# -gt 0 ]; do
   : debug: $1
   case $1 in
		--help)
			usage
			exit 0
			;;
		-T|--type)
			TYPE=$2
			shift 2;;
		-p|--proxy)
			PROXY_URL=$2
			shift 2;;
		-r|--raw)
			RAW_URL=$2
			shift 2;;
		-P|--port)
			PORT=$2
			shift 2;;
		-n|--name)
			NAME=$2
			shift 2;;
		-t|--total)
			TOTAL=$2
			shift 2;;
		-o|--output)
			OUTPUT=$2
			shift 2;;
		-u|--url)
			URL=$2
			shift 2;;
		-c|--concurrent)
			CONCURRENT=$2
			shift 2;;
		-v)
			VERBOSE=true
			shift;;
		--)
			shift
			break;;
		*)
			print_usage; exit 0
			;;
	esac
done

OUTPUT="$OUTPUT.$TOTAL.$CONCURRENT"

if [ -z $PROXY_URL ]; then
	echo "Proxy url is required"
	print_usage
	exit 1
fi
if [ -z $RAW_URL ]; then
	echo "Raw url is required"
	print_usage
	exit 1
fi

echo "set   autoscale                        # scale axes automatically
unset log                              # remove any log-scaling
unset label                            # remove any previous labels
set xtic auto                          # set xtics automatically
set ytic auto                          # set ytics automatically

set terminal png
set title 'Proxy vs. raw response times ($PROXY_URL)'
set xlabel 'Request'
set ylabel 'ms'
set size 2,1
set key left top
set output '$OUTPUT.png'" > $PLOT_OUTPUT_SCRIPT

echo "Testing proxy at url: http://$PROXY_URL"
echo "Adding backend: "
echo "curl -i -XPOST -d\"{\"app_name\":\"$NAME\", \"host\":\"$RAW_URL\", \"port\":\"$PORT\"}\" http://$PROXY_URL:$PORT/backend/new"
curl -i -XPOST -d"{\"app_name\":\"$NAME\", \"host\":\"$RAW_URL\", \"port\":\"$PORT\"}" http://$PROXY_URL:$PORT/backend/new

case $TYPE in
	"comparison")
		run_comparison_graph
		;;
	"proxy")
		run_proxy_graph
		;;
	*)
		echo "
			Current supported types are comparison and proxy
		"
		exit 0
		;;
esac

$GNUPLOT $PLOT_OUTPUT_SCRIPT > /dev/null

echo "The graph has been saved to $OUTPUT";

echo "curl -i -XDELETE -d\"{}\" http://$PROXY_URL/backend/$NAME/$RAW_URL/$PORT"
curl -i -XDELETE -d"{}" http://$PROXY_URL:$PORT/backend/$NAME/$RAW_URL/$PORT
rm /tmp/graph-*
