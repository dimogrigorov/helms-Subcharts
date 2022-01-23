#!/bin/sh
#exec >logfile.txt 2>&1
GRATER_THEN="now-90d/d"   #From time
LESS_THEN="now/d"

while [[ $# > 0 ]]; do
    key="$1"
    case $key in

    -g)
      GRATER_THEN=$2
      shift
    ;;

    -l)
      LESS_THEN=$2
      shift
    ;;

    -h|--help|-?)
      echo "Usage:"
      echo "$0 [options]"
      echo " -l <less_then>      Default: $LESS_THEN"
      echo " -g <greater_then>   Default: $GRATER_THEN"
      exit 0
    ;;
    *)
      # unknown option
      echo "Error: unknown option $1"
      exit 1
    ;;
    esac
    shift # past argument or value
done

ELK_URL="http://es.sofia.ifao.net:9200/ccbd.app.*/_search?pretty&scroll=1m"
ELK_URL_POST="http://es.sofia.ifao.net:9200/_search/scroll?pretty"
STATS_FILE=stats.csv    #data file
SEARCH_STRING="Booking event processing time*"   #String to search
temp_file="extract.csv"
homedir=$(dirname $0)

get_events() {

cat <<EOF > /tmp/temp_qry
{
       "from" : 0,
       "size" : 10,
       "query": {
        "bool": {
          "must": [
            {
              "range": {
                "@timestamp": {
                  "gte": "$GRATER_THEN",
                  "lte": "$LESS_THEN"
                }
              }
            },
            {
              "match": {
                "log": "$SEARCH_STRING"
              }
            }
          ]
        }
      }
    }
EOF

response=$(curl -s -X  GET "${ELK_URL}" -H 'Content-Type: application/json' -d@/tmp/temp_qry)
response="'$response'"
echo $response
scroll_id=$(jq -r "_scroll_id" $response)

echo "scroll_id: $scroll_id"
}
#for VARIABLE in 1 .. 9
#do
        #response=$(curl -s -X  POST "${ELK_URL_POST}" -H 'Content-Type: application/json' -d'
#	{ 
	#	"scroll" : "1m", 
#		"scroll_id" : "$scroll_id"
#	}')
#	scroll_id=response._scroll_id
#	get_events |  jq -r .hits.hits[]._source.log >> ${temp_file}
#done
# Getting the data
get_events #|  jq -r input_line_number .hits.hits[]._source.log' >> ${temp_file}

#get_events |  jq -r "\(input_line_number): \(.hits.hits[]._source.log)" >> ${temp_file}
##Trimming retrieved data
#awk '{print $1,$2,";",$13}' ${temp_file} > "$homedir"/"$STATS_FILE"


#cat "$homedir"/"$STATS_FILE"
#echo "Stats are available in ${STATS_FILE} file"

#matches=$(cat ${temp_file} |wc -l)
#trimmed_matches=$(cat "$homedir"/"$STATS_FILE" |wc -l)

#if [ "$matches" -ne "$trimmed_matches" ]; then
#echo "AWK truncated some of the results"
#echo "Search returned ${matches}"
#echo "After trimming there are ${trimmed_matches}"
#fi
