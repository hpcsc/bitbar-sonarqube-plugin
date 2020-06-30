#!/bin/bash

TIMEOUT=20
wait_for_sonarqube() {
    echo "=== waiting for sonarqube at ${SONARQUBE_URL} to be up"
    for i in $(seq ${TIMEOUT}) ; do
        local status=$(curl -s ${SONARQUBE_URL}/api/system/status | jq -r '.status')

        if [ "${status}" == "UP" ]; then
            echo "=== Sonarqube is up"
            return;
        else
            echo "=== [${i}] Sonarqube is not yet up: [${status}], sleeping for 5s"
        fi;

        sleep 5s
    done;
}

wait_for_sonarqube

rm -rf ./scannerwork ./sonar

sonar-scanner

echo "=== Finished running sonar scanning"
tail -f /dev/null
