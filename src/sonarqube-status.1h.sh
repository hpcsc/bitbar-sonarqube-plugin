#!/usr/bin/env bash

# <bitbar.title>Sonarqube Project Status</bitbar.title>
# <bitbar.version>v1.0</bitbar.version>
# <bitbar.author>David Nguyen</bitbar.author>
# <bitbar.author.github>hpcsc</bitbar.author.github>
# <bitbar.desc>Displays statistics from Sonarqube projects</bitbar.desc>
# <bitbar.dependencies>jq,curl</bitbar.dependencies>
# <bitbar.image>https://i.imgur.com/BJ9SNIh.png</bitbar.image>
# <bitbar.abouturl>https://github.com/hpcsc/bitbar-teamcity-plugin</bitbar.abouturl>
#
# Displays statistics from Sonarqube projects
#
# CONFIGURATION
# - Follow instruction at https://docs.sonarqube.org/latest/user-guide/user-token/ to generate an user token
# - Fill in configuration in .bitbar-sonarqube-plugin.json in Bitbar plugins folder

export PATH=/usr/local/bin:${PATH}

if ([[ "$(type -t jq)" != "function" ]] && [[ ! -x "$(command -v jq)" ]]) ||
    ([[ "$(type -t curl)" != "function" ]] && [[ ! -x "$(command -v curl)" ]]); then
    echo "=== jq and curl are required for this plugin"
    echo "They are either not installed or not available at PATH=${PATH}"
    exit 1
fi;

SCRIPT_DIR=$(cd $(dirname $0); pwd)
CONFIG_FILE=${1:-${SCRIPT_DIR}/.bitbar-sonarqube-plugin.json}

CONFIG=$(cat ${CONFIG_FILE})
TOKEN=$(echo ${CONFIG} | jq -r '.token')
SERVER=$(echo ${CONFIG} | jq -r '.server')
PROJECT_KEYS=$(echo ${CONFIG} | jq -r '.projectKeys[]')
FROM=$(echo ${CONFIG} | jq -r '.from | select (. != null)')
UNTIL=$(echo ${CONFIG} | jq -r '.until | select (. != null)')
DAYS_OF_WEEK=$(echo ${CONFIG} | jq -r '.daysOfWeek | select (. != null)')

OPEN_SONARQUBE="Open Sonarqube | href=${SERVER}"

print_inactive_output() {
    echo "Sonarqube:INACTIVE | color=gray"
    echo "---"
    echo "${OPEN_SONARQUBE}"
}

if ([[ -n "${UNTIL}" ]] && [[ "$(date '+%H:%M')" > "${UNTIL}" ]]) ||
   ([[ -n "${FROM}" ]] && [[ "$(date '+%H:%M')" < "${FROM}" ]]); then
    print_inactive_output
    exit 0
fi;

if [[ -n "${DAYS_OF_WEEK}" ]] && [[ "${DAYS_OF_WEEK}," != *"$(date '+%u'),"* ]]; then
    print_inactive_output
    exit 0
fi;

echo "Sonarqube | color=green"
echo "---"

for PROJECT_KEY in ${PROJECT_KEYS}; do
    DATA=$(curl -H 'Accept: application/json' \
                -u "${TOKEN}:" \
                -s \
                --max-time 3 \
                ${SERVER}/api/measures/component?component=${PROJECT_KEY}\&metricKeys=code_smells,vulnerabilities,coverage,duplicated_lines_density
            )

    if [[ $? -ne 0 ]]; then
        echo "Unable to reach Sonarqube | color=red"
        break
    else
        case "${DATA}" in
            *"error"*)
                ERROR=$(echo "${DATA}" | jq -r '[.errors[].msg] | join(", ")')
                echo "${ERROR} | color=red"
                ;;
            *"Access Denied"*)
                echo "Access Denied | color=red"
                break
                ;;
            *)
                PROJECT_NAME=$(echo ${DATA} | jq -r '.component.name')
                CODE_SMELLS=$(echo ${DATA} | jq -r '.component.measures[] | select(.metric == "code_smells") | .value')
                VULNERABILITIES=$(echo ${DATA} | jq -r '.component.measures[] | select(.metric == "vulnerabilities") | .value')
                DUPLICATED=$(echo ${DATA} | jq -r '.component.measures[] | select(.metric == "duplicated_lines_density") | .value')
                COVERAGE=$(echo ${DATA} | jq -r '.component.measures[] | select(.metric == "coverage") | .value')

                echo "${PROJECT_NAME} | href=${SERVER}/dashboard?id=${PROJECT_KEY}"
                echo "-- ${CODE_SMELLS} code smells | href=${SERVER}/project/issues?id=${PROJECT_KEY}&resolved=false&types=CODE_SMELL"
                echo "-- ${VULNERABILITIES} vulnerabilities | href=${SERVER}/project/issues?id=${PROJECT_KEY}&resolved=false&types=VULNERABILITY"
                echo "-- ${DUPLICATED}% duplicates | href=${SERVER}/component_measures?id=${PROJECT_KEY}&metric=duplicated_lines_density&view=list"
                echo "-- ${COVERAGE}% coverage | href=${SERVER}/component_measures?id=${PROJECT_KEY}&metric=coverage&view=list"
                ;;
        esac
    fi;
done;

echo "---"
echo "${OPEN_SONARQUBE}"
