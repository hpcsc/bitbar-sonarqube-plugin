FROM sonarqube:7.9.3-community

RUN curl -L https://github.com/emerald-squad/sonar-shellcheck-plugin/releases/download/v1.1.3/sonar-shellcheck-plugin-1.1.3.jar \
-o /opt/sonarqube/extensions/plugins/sonar-shellcheck-plugin-1.1.3.jar
