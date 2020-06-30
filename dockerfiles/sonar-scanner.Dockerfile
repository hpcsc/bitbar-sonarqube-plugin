FROM sonarsource/sonar-scanner-cli:4.3

USER root
RUN apt-get update && apt-get install -y curl jq

USER scanner-cli
WORKDIR /app
