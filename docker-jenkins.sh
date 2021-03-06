#!/bin/sh
CMD_BASE="$(readlink -f "$0")" || CMD_BASE="$0"; CMD_BASE="$(dirname "$CMD_BASE")"

IMAGE="elifarley/docker-jenkins-uidfv"

docker pull "$IMAGE"

curl -fsL --connect-timeout 1 http://169.254.169.254/latest/meta-data/local-ipv4 >/dev/null && {
  hostname="$(hostname)"
  log_stream_name="$(date +'%Y%m%d.%H%M%S')/$(echo ${hostname%%.*}/${IMAGE##*:} | tr -s ':* ' ';..')"
  log_config="
  --log-driver=awslogs
  --log-opt awslogs-group=/jenkins/master
  --log-opt awslogs-stream=$log_stream_name
  "
  echo "Log stream name: $log_stream_name"
  cp -av ~/.ssh/*.p?? "$CMD_BASE"/../mnt-ssh-config/
}

#--log-opt awslogs-region=sa-east-1 \
#

dimg() { docker inspect "$1" |grep Image | grep -v sha256: | cut -d'"' -f4 ;}
dstatus() { docker inspect "$1" | grep Status | cut -d'"' -f4 ;}

drun() {
  local name="$1"; test $# -gt 0 && shift
  local status="$(dstatus "$name" 2>/dev/null)"; echo "Container status for '$name': $status"
  test "$status" = running && echo "STOPPING at $(date)"

  case "$status" in running|restarting|created)
    echo "OLD IMAGE: $(dimg "$name")"
    docker stop >/dev/null -t 30 "$name" && docker >/dev/null rm "$name" || exit
  ;; exited) docker >/dev/null rm "$name" || exit
  ;; '') echo "Container '$name' not found."
  ;; *) echo "Unknown container status: $status"; docker ps | grep "$name"; docker rm -f "$name"
  esac

  ( set -x
docker run --name "$name" -d --restart=always \
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
$log_config \
"$IMAGE" "$@"
  ) || return

  echo "DOWNTIME END: $(date)"
}

drun jenkins
