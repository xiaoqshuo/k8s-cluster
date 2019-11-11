#!/bin/bash

# Copyright 2014 The Kubernetes Authors.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

eval REDIS_SENTINEL_SERVICE_HOST=\${$(echo ${NAME}|tr 'a-z' 'A-Z')_STL_SERVICE_HOST}
eval REDIS_SENTINEL_SERVICE_PORT=\${$(echo ${NAME}|tr 'a-z' 'A-Z')_STL_SERVICE_PORT}
REDIS_MASTER_SERVICE_HOST=$(dig +short ${NAME}-0.${NAME}.${NAMESPACE}.svc.cluster.local)
((MAXMEMORY=${MY_MEM_LIMIT}-1073741824))


function launchredis() {
  sleep 3
  while true; do
    master=$(redis-cli -a $REDIS_PASS -h ${REDIS_SENTINEL_SERVICE_HOST} -p ${REDIS_SENTINEL_SERVICE_PORT} --csv SENTINEL get-master-addr-by-name mymaster | tr ',' ' ' | cut -d' ' -f1)
    if [[ -n ${master} ]]; then
      master="${master//\"}"
    else
      echo $REDIS_MASTER_SERVICE_HOST
      master=${REDIS_MASTER_SERVICE_HOST}
      echo $master
      if [[ "$(hostname -i)" == "${master}" ]]; then
          echo "Failed to find master."
          sed -i "s/%redis-pass%/${REDIS_PASS}/" /redis-data/conf/redis.conf
          sed -i "s/%redis-port%/${REDIS_PORT}/" /redis-data/conf/redis.conf
          echo $MAXMEMORY
          sed -i "s/%max-memory%/${MAXMEMORY}/" /redis-data/conf/redis.conf
          touch /redis-data/data/redis.log
          /redis-data/bin/redis-server /redis-data/conf/redis.conf --protected-mode no
          tail -f /redis-data/data/redis.log
          exit 1
      fi
    fi
    sleep 30
    /redis-data/bin/redis-cli -a $REDIS_PASS -p ${REDIS_PORT} -h ${master} INFO
    if [[ "$?" == "0" ]]; then
      break
    fi
    echo "Connecting to master failed.  Waiting..."
    sleep 10
  done
  sed -i "s/%master-ip%/${master}/" /redis-data/conf/redis.conf
  sed -i "s/%redis-pass%/${REDIS_PASS}/" /redis-data/conf/redis.conf
  sed -i "s/%redis-port%/${REDIS_PORT}/" /redis-data/conf/redis.conf
  echo $MAXMEMORY
  sed -i "s/%max-memory%/${MAXMEMORY}/" /redis-data/conf/redis.conf
  echo -e "slaveof ${master} ${REDIS_PORT}\nslave-read-only yes" >>/redis-data/conf/redis.conf
  touch /redis-data/data/redis.log
  /redis-data/bin/redis-server /redis-data/conf/redis.conf --protected-mode no
  tail -f /redis-data/data/redis.log
}

function launchsentinel() {
  sleep 3
  while true; do
    master=$(redis-cli -a $REDIS_PASS -h ${REDIS_SENTINEL_SERVICE_HOST} -p ${REDIS_SENTINEL_SERVICE_PORT} --csv SENTINEL get-master-addr-by-name mymaster | tr ',' ' ' | cut -d' ' -f1)
    if [[ -n ${master} ]]; then
      master="${master//\"}"
    else
      sleep 10
      echo $REDIS_MASTER_SERVICE_HOST
      master=${REDIS_MASTER_SERVICE_HOST}
      echo $master
    fi
    /redis-data/bin/redis-cli -a ${REDIS_PASS} -p ${REDIS_PORT} -h ${master} INFO
    if [[ "$?" == "0" ]]; then
      break
    fi
    echo "Connecting to master failed.  Waiting..."
    sleep 10
  done

  sentinel_conf=/redis-data/conf/sentinel.conf
  echo "sentinel monitor mymaster ${master} ${REDIS_PORT} 2" > ${sentinel_conf}
  echo "sentinel auth-pass mymaster ${REDIS_PASS}" >> ${sentinel_conf}
  echo "sentinel down-after-milliseconds mymaster 10000" >> ${sentinel_conf}
  echo "sentinel failover-timeout mymaster 30000" >> ${sentinel_conf}
  echo "sentinel parallel-syncs mymaster 1" >> ${sentinel_conf}
  echo "port ${SENTINEL_PORT}" >> ${sentinel_conf}
  echo "bind 0.0.0.0" >> ${sentinel_conf}
  echo "protected-mode no" >> ${sentinel_conf}
  echo "daemonize yes" >> ${sentinel_conf}
  echo 'logfile "/redis-data/data/redis.log"' >> ${sentinel_conf}
  touch /redis-data/data/redis.log
  /redis-data/bin/redis-sentinel ${sentinel_conf} --protected-mode no
  tail -f /redis-data/data/redis.log
}


if [[ "${SENTINEL}" == "true" ]]; then
  launchsentinel
  exit 0
fi

launchredis
