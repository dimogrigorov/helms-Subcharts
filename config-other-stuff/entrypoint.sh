#!/bin/sh

sh check_for_repo_change.sh &
java -jar config-server.jar 

