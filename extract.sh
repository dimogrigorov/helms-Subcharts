#!/bin/sh

# docker run -ti --rm -v C:\Users\kkrumov\Documents\vscode\notes:/opt/ dwdraju/alpine-curl-jq sh -x /opt/get_ccbd_booking_event_processing_time.sh
ELK_URL="http://es.sofia.ifao.net:9200/ccbd.app.*/_search?pretty"
STATS_FILE=stats.csv    #data file
SEARCH_STRING="Booking event processing time*"   #String to search
temp_file="extract.csv"
GRATER_THEN="now-1d/d"   #From time
LESS_THEN="now/d"         #To time
homedir=$(dirname $0)

get_events() {

cat <<EOF > /tmp/temp_qry
{
       "from" : 0,
       "size" : 2000,
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
    curl -s -X  GET "${ELK_URL}" -H 'Content-Type: application/json' -d@/tmp/temp_qry
}
# Getting the data
get_events |  jq -r .hits.hits[]._source.log >> ${temp_file}

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