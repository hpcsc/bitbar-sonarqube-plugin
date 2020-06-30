#!/usr/bin/env bash

TEMPLATE=$(cat <<EOF
{
    "component": {
        "id": "AXMEyHtW7dsQ9ZqqK5-x",
        "key": "{project-key}",
        "name": "{project-key}",
        "qualifier": "TRK",
        "measures": [
            {
                "metric": "vulnerabilities",
                "value": "2",
                "bestValue": true
            },
            {
                "metric": "code_smells",
                "value": "24",
                "bestValue": false
            },
            {
                "metric": "duplicated_lines_density",
                "value": "2.0",
                "bestValue": true
            },
            {
                "metric": "coverage",
                "value": "93.4",
                "bestValue": false
            }
        ]
    }
}
EOF
)

generate_fake_response() {
    local project_key=${1}
    echo ${TEMPLATE} | sed 's/{project-key}/'${project_key}'/g'
}
