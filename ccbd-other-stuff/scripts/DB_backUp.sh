#!/bin/sh

#to run the script: > ./DB_backUp.sh <DB container name>

dbImageName=$1
today=$(date +%Y-%m-%d_%H_%M_%S)
dumpfileName="cytricqa_DB_Clone${today}.dmp"
localDumpFileFolder="/home/appuser/backup/db_backup/"

echo "Dump file name: ${dumpfileName}"
echo "Docker Image name: ${dbImageName}"

#log to the bash of Db container
#docker exec -it $dbImageName bash
#cd /etalon/

#export the DB data to a dump file 
docker exec $dbImageName sh -c "expdp cytricqa/Amadeus123@localhost:1521/ORCLPDB1.localdomain directory=my_data_pump_directory DUMPFILE=$dumpfileName SCHEMAS=cytricqa logfile=cytricqa.log"

# exit out of docker container
#exit

#copy the dump file from container to local folder
docker cp $dbImageName:/etalon/$dumpfileName $localDumpFileFolder/$dumpfileName
echo "Dump file copied to >> ${localDumpFileFolder}/${dumpfileName}"

#docker exec -it $dbImageName bash
#remove dump file from the container
docker exec $dbImageName sh -c "rm -rf /etalon/$dumpfileName"

#exit
