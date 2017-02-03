#!/bin/sh
CMD_BASE="$(readlink -f "$0")" || CMD_BASE="$0"; CMD_BASE="$(dirname "$CMD_BASE")"

IMAGE="elifarley/docker-jenkins-uidfv:2-latest"

set -x
docker pull "$IMAGE"

curl -fsL --connect-timeout 1 http://169.254.169.254/latest/meta-data/local-ipv4 >/dev/null && {
  hostname="$(hostname)"
  log_stream_name="$(date +'%Y%d%m-%H%M%S') $(echo ${hostname%%.*} ${IMAGE##*:} | tr -s ':*' ';.')"
  log_config="
  --log-driver=awslogs
  --log-opt awslogs-group=/jenkins/master
  --log-opt awslogs-stream=$log_stream_name
  "
  cp -av ~/.ssh/*.p?? "$CMD_BASE"/../mnt-ssh-config/
  echo "Log stream name: $log_stream_name"
}

#--log-opt awslogs-region=sa-east-1 \
# 

dimg() { docker inspect "$1" |grep Image | grep -v sha256: | cut -d'"' -f4 ;}
dstatus() { docker inspect "$1" | grep Status | cut -d'"' -f4 ;}

test "$(dstatus jenkins 2>/dev/null)" = running && {
  echo "OLD IMAGE: $(dimg jenkins)"
  docker stop jenkins
}

docker rm jenkins

exec docker run --name jenkins \
-p 8080:8080 -p 50000:50000 -p 9910:9910 -p 9911:9911 \
--dns=10.11.64.21 --dns=10.11.64.22 --dns-search=m4ucorp.dmc \
-v "$CMD_BASE"/../..:/var/jenkins_home \
-v "$CMD_BASE"/../mnt-ssh-config:/mnt-ssh-config:ro \
-e JENKINS_OPTS="--prefix=/jenkins" \
-e JAVA_OPTS="\
-Dcom.sun.management.jmxremote \
-Dcom.sun.management.jmxremote.ssl=false \
-Dcom.sun.management.jmxremote.authenticate=false \
-Dcom.sun.management.jmxremote.port=9910 \
-Dcom.sun.management.jmxremote.rmi.port=9911 \
-Djava.rmi.server.hostname=$(curl -fsL --connect-timeout 1 http://169.254.169.254/latest/meta-data/local-ipv4 || hostname)" \
-d --restart=always \
$log_config \
"$IMAGE" "$@"
