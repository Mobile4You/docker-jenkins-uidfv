FROM jenkins:alpine
MAINTAINER Elifarley Cruz <elifarley@gmail.com>

# See https://github.com/bdruemen/jenkins-docker-uid-from-volume/blob/master/Dockerfile
# Modify the UID of the jenkins user to automatically match the mounted volume.
# Use it just like the original: https://hub.docker.com/_/jenkins/

USER root

ENV TZ ${TZ:-Brazil/East}

RUN echo http://nl.alpinelinux.org/alpine/edge/testing >> /etc/apk/repositories && \
  apk --update add --no-cache openssh-client git shadow tzdata && \
  echo "TZ set to '$TZ'" && cp -a /usr/share/zoneinfo/"$TZ" /etc/localtime && apk del tzdata && \
  rm -rf /var/cache/apk/*

# Grab gosu for easy step-down from root.
ADD https://github.com/tianon/gosu/releases/download/1.5/gosu-amd64 /usr/local/bin/gosu

# Change the group of the jenkins user to root, because that group has no 
# special rights on most host systems.
RUN chmod 755 /usr/local/bin/gosu

ENTRYPOINT usermod -u $(stat -c "%u" /var/jenkins_home) jenkins && \
        gosu jenkins /bin/tini -- /usr/local/bin/jenkins.sh
