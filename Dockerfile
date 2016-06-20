FROM jenkins:alpine
MAINTAINER Elifarley Cruz <elifarley@gmail.com>
ENV BASE_IMAGE=jenkins:alpine \
\
GOSU_VERSION='1.5' GOSU_SHA=18cced029ed8f0bf80adaa6272bf1650ab68f7aa \
_USER=jenkins \
TZ=${TZ:-Brazil/East} \
TERM=xterm-256color \
MNT_DIR=/var/jenkins_home

ENV HOME=/$_USER JAVA_TOOL_OPTIONS="-Duser.timezone=$TZ"

# See https://github.com/bdruemen/jenkins-docker-uid-from-volume/blob/master/Dockerfile
# Modify the UID of the jenkins user to automatically match the mounted volume.
# Use it just like the original: https://hub.docker.com/_/jenkins/

ENTRYPOINT ["/bin/tini", "--", "/entry.sh"]
CMD ["/usr/sbin/sshd", "-D", "-f", "/etc/ssh/sshd_config"]

ENTRYPOINT usermod -u $(stat -c "%u" /var/jenkins_home) jenkins && \
        exec /bin/tini -- gosu jenkins /usr/local/bin/jenkins.sh

curl -fsSL https://raw.githubusercontent.com/elifarley/cross-installer/master/install.sh | sh && \
  xinstall install timezone && \
  xinstall save-image-info && \
  xinstall install-base && \
  xinstall install gosu "$GOSU_VERSION" "$GOSU_SHA" && \
  xinstall cleanup
