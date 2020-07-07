#!/usr/bin/env bats

load 'test_helper/bats-support/load'
load 'test_helper/bats-assert/load'

teardown() {
  unset -f date
  unset -f security
  unset -f curl
}

@test "return INACTIVE if current time is before from field" {
  date() { echo "05:25"; }
  export -f date

CONFIG=$(cat <<'EOF'
{
    "token": "some-token",
    "server": "http://localhost:9000",
    "projectKeys": [
        "bitbar-sonarqube-plugin"
    ],
    "from": "09:00"
}
EOF
)

  BASE_DIR=$(dirname ${BATS_TEST_DIRNAME})
  run ${BASE_DIR}/src/sonarqube-status.1h.sh <(echo ${CONFIG})

  assert_success
  assert_output --partial 'INACTIVE'
}

@test "return INACTIVE if current time is after until field" {
  date() { echo "17:01"; }
  export -f date

CONFIG=$(cat <<'EOF'
{
    "token": "some-token",
    "server": "http://localhost:9000",
    "projectKeys": [
        "bitbar-sonarqube-plugin"
    ],
    "until": "17:00"
}
EOF
)

  BASE_DIR=$(dirname ${BATS_TEST_DIRNAME})
  run ${BASE_DIR}/src/sonarqube-status.1h.sh <(echo ${CONFIG})

  assert_success
  assert_output --partial 'INACTIVE'
}

@test "return INACTIVE if current date is not within configured daysOfWeek" {
  date() {
    if [ "$1" = "+%H:%M" ]; then
      echo "17:01";
    else
      echo "2";
    fi;
  }
  export -f date

CONFIG=$(cat <<'EOF'
{
    "token": "some-token",
    "server": "http://localhost:9000",
    "projectKeys": [
        "bitbar-sonarqube-plugin"
    ],
    "daysOfWeek": "1,3,4,5"
}
EOF
)

  BASE_DIR=$(dirname ${BATS_TEST_DIRNAME})
  run ${BASE_DIR}/src/sonarqube-status.1h.sh <(echo ${CONFIG})

  assert_success
  assert_output --partial 'INACTIVE'
}

@test "return failed if not able to reach Sonarqube after timeout period" {
CONFIG=$(cat <<'EOF'
{
    "token": "some-token",
    "server": "http://not-existing-server:9000",
    "projectKeys": [
        "bitbar-sonarqube-plugin"
    ]
}
EOF
)

  BASE_DIR=$(dirname ${BATS_TEST_DIRNAME})
  run ${BASE_DIR}/src/sonarqube-status.1h.sh <(echo ${CONFIG})

  assert_success
  assert_output --partial 'Unable to reach Sonarqube'
}

@test "return response error if response contains errors field" {
  curl() {
    echo '{"errors":[{"msg":"error 1"},{"msg":"error 2"}]}'
  }
  export -f curl
CONFIG=$(cat <<'EOF'
{
    "token": "some-token",
    "server": "http://not-existing-server:9000",
    "projectKeys": [
        "bitbar-sonarqube-plugin"
    ]
}
EOF
)

  BASE_DIR=$(dirname ${BATS_TEST_DIRNAME})
  run ${BASE_DIR}/src/sonarqube-status.1h.sh <(echo ${CONFIG})

  assert_success
  assert_output --partial 'error 1, error 2'
}

@test "return access denied if response contains access denied" {
  curl() {
    echo '<HTML><HEAD><TITLE>Access Denied</TITLE></HEAD><BODY><H1>Access Denied</H1>You don''t have permission to access</BODY></HTML>'
  }
  export -f curl
CONFIG=$(cat <<'EOF'
{
    "token": "some-token",
    "server": "http://localhost:9000",
    "projectKeys": [
        "bitbar-sonarqube-plugin"
    ]
}
EOF
)

  BASE_DIR=$(dirname ${BATS_TEST_DIRNAME})
  run ${BASE_DIR}/src/sonarqube-status.1h.sh <(echo ${CONFIG})

  assert_success
  assert_output --partial 'Access Denied'
}


@test "return links to measures" {
  curl() {
    source 'tests/fake-sonarqube-response-generator.sh'
    generate_fake_response project-1
  }
  export -f curl

CONFIG=$(cat <<'EOF'
{
    "token": "some-token",
    "server": "http://localhost:9000",
    "projectKeys": [
        "bitbar-sonarqube-plugin"
    ]
}
EOF
)

  BASE_DIR=$(dirname ${BATS_TEST_DIRNAME})
  run ${BASE_DIR}/src/sonarqube-status.1h.sh <(echo ${CONFIG})

  assert_success
  assert_output --partial '2 vulnerabilities'
  assert_output --partial '24 code smells'
  assert_output --partial '2.0% duplicates'
  assert_output --partial '93.4% coverage'
}
