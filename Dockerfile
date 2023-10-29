FROM alpine:latest
LABEL "repository"="https://github.com/kuczko/semver-action"
LABEL "homepage"="https://github.com/kuczko/semver-action"
LABEL "maintainer"="Mateusz Kaminski"

RUN apk --no-cache add bash git 

COPY entrypoint.sh /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
