#!/usr/bin/env bash
# Licensed to the Apache Software Foundation (ASF) under one
# or more contributor license agreements.  See the NOTICE file
# distributed with this work for additional information
# regarding copyright ownership.  The ASF licenses this file
# to you under the Apache License, Version 2.0 (the
# "License"); you may not use this file except in compliance
# with the License.  You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

## @description  install yarn
## @audience     public
## @stability    stable
function install_yarn()
{
  mkdir -p "${INSTALL_TEMP_DIR}/hadoop/yarn"
  cp -R "${PACKAGE_DIR}/hadoop/yarn/*" "${INSTALL_TEMP_DIR}/hadoop/yarn"

  kinit - kt ${HADOOP_KEYTAB_LOCATION} ${HADOOP_PRINCIPAL}

  install_yarn_rm_nm
  install_yarn_service
  install_registery_dns
  install_job_history
  install_mapred
  install_spark_suffle
  install_yarn_sbin
  install_yarn_container_executor

  # copy file
  cp -f "$INSTALL_TEMP_DIR/hadoop/yarn/etc/yarn-site.xml" "${HADOOP_HOME}/etc/hadoop/"
  cp -f "$INSTALL_TEMP_DIR/hadoop/yarn/etc/mapred-site.xml" "${HADOOP_HOME}/etc/hadoop/"
  cp -f "$INSTALL_TEMP_DIR/hadoop/yarn/etc/core-site.xml" "${HADOOP_HOME}/etc/hadoop/"
  cp -f "$INSTALL_TEMP_DIR/hadoop/yarn/etc/hdfs-site.xml" "${HADOOP_HOME}/etc/hadoop/"
}

## @description  uninstall yarn
## @audience     public
## @stability    stable
function uninstall_yarn()
{
  rm -rf /etc/yarn/sbin/Linux-amd64-64/*
  rm -rf /etc/yarn/sbin/etc/hadoop/*
}

## @description  download yarn container executor
## @audience     public
## @stability    stable
function download_yarn_container_executor()
{
  # my download http server
  if [[ -n "$DOWNLOAD_HTTP" ]]; then
    MY_YARN_CONTAINER_EXECUTOR_PATH="${DOWNLOAD_HTTP}/downloads/hadoop/container-executor"
  else
    MY_YARN_CONTAINER_EXECUTOR_PATH=${YARN_CONTAINER_EXECUTOR_PATH}
  fi

  if [ ! -d "${DOWNLOAD_DIR}/hadoop" ]; then
    mkdir -p "${DOWNLOAD_DIR}/hadoop"
  fi

  if [[ -f "${DOWNLOAD_DIR}/hadoop/container-executor" ]]; then
    echo "${DOWNLOAD_DIR}/hadoop/container-executor already exists."
  else
    if [[ -n "$DOWNLOAD_HTTP" ]]; then
      echo "download ${MY_YARN_CONTAINER_EXECUTOR_PATH} ..."
      wget -P "${DOWNLOAD_DIR}/hadoop" "${MY_YARN_CONTAINER_EXECUTOR_PATH}"
    else
      echo "copy ${MY_YARN_CONTAINER_EXECUTOR_PATH} ..."
      cp "${MY_YARN_CONTAINER_EXECUTOR_PATH}" "${DOWNLOAD_DIR}/hadoop/"
    fi
  fi
}

## @description  install yarn container executor
## @audience     public
## @stability    stable
function install_yarn_container_executor()
{
  echo "install yarn container executor file ..."

  download_yarn_container_executor

  if [ ! -d "/etc/yarn/sbin/Linux-amd64-64" ]; then
    mkdir -p /etc/yarn/sbin/Linux-amd64-64
  fi
  if [ -f "/etc/yarn/sbin/Linux-amd64-64/container-executor" ]; then
    rm /etc/yarn/sbin/Linux-amd64-64/container-executor
  fi

  cp -f "${DOWNLOAD_DIR}/hadoop/container-executor" /etc/yarn/sbin/Linux-amd64-64

  sudo chmod 6755 /etc/yarn/sbin/Linux-amd64-64
  sudo chown :yarn /etc/yarn/sbin/Linux-amd64-64/container-executor
  sudo chmod 6050 /etc/yarn/sbin/Linux-amd64-64/container-executor
}

## @description  install yarn resource & node manager
## @audience     public
## @stability    stable
function install_yarn_rm_nm()
{
  echo "install yarn config file ..."

  find="/"
  replace="\\/"
  escape_yarn_nodemanager_local_dirs=${YARN_NODEMANAGER_LOCAL_DIRS//$find/$replace}
  escape_yarn_nodemanager_log_dirs=${YARN_NODEMANAGER_LOG_DIRS//$find/$replace}
  escape_yarn_hierarchy=${YARN_HIERARCHY//$find/$replace}

  # container-executor.cfg
  sed -i "s/YARN_NODEMANAGER_LOCAL_DIRS_REPLACE/${escape_yarn_nodemanager_local_dirs}/g" "$INSTALL_TEMP_DIR/hadoop/yarn/etc/container-executor.cfg"
  sed -i "s/YARN_NODEMANAGER_LOG_DIRS_REPLACE/${escape_yarn_nodemanager_log_dirs}/g" "$INSTALL_TEMP_DIR/hadoop/yarn/etc/container-executor.cfg"
  sed -i "s/DOCKER_REGISTRY_REPLACE/${DOCKER_REGISTRY}/g" "$INSTALL_TEMP_DIR/hadoop/yarn/etc/container-executor.cfg"
  sed -i "s/CALICO_NETWORK_NAME_REPLACE/${CALICO_NETWORK_NAME}/g" "$INSTALL_TEMP_DIR/hadoop/yarn/etc/container-executor.cfg"
  sed -i "s/YARN_HIERARCHY_REPLACE/${escape_yarn_hierarchy}/g" "$INSTALL_TEMP_DIR/hadoop/yarn/etc/container-executor.cfg"

  # Delete the ASF license comment in the container-executor.cfg file, otherwise it will cause a cfg format error.
  sed -i '1,16d' "$INSTALL_TEMP_DIR/hadoop/yarn/etc/container-executor.cfg"

  if [ ! -d "/etc/yarn/sbin/etc/hadoop" ]; then
    mkdir -p /etc/yarn/sbin/etc/hadoop
  fi

  cp -f "$INSTALL_TEMP_DIR/hadoop/yarn/etc/container-executor.cfg" /etc/yarn/sbin/etc/hadoop/

  # yarn-site.xml
  sed -i "s/YARN_RESOURCE_MANAGER_HOSTS1_REPLACE/${YARN_RESOURCE_MANAGER_HOSTS[0]}/g" "$INSTALL_TEMP_DIR/hadoop/yarn/etc/yarn-site.xml"
  sed -i "s/YARN_RESOURCE_MANAGER_HOSTS2_REPLACE/${YARN_RESOURCE_MANAGER_HOSTS[1]}/g" "$INSTALL_TEMP_DIR/hadoop/yarn/etc/yarn-site.xml"
  sed -i "s/HTTP_KEYTAB_LOCATION_REPLACE/${HTTP_KEYTAB_LOCATION}/g" "$INSTALL_TEMP_DIR/hadoop/yarn/etc/yarn-site.xml"
  sed -i "s/HTTP_PRINCIPAL_REPLACE/${HTTP_PRINCIPAL}/g" "$INSTALL_TEMP_DIR/hadoop/yarn/etc/yarn-site.xml"
  sed -i "s/LOCAL_CLUSTER_ID_REPLACE/${LOCAL_CLUSTER_ID}/g" "$INSTALL_TEMP_DIR/hadoop/yarn/etc/yarn-site.xml"
  sed -i "s/YARN_NODEMANAGER_LOCAL_DIRS_REPLACE/${escape_yarn_nodemanager_local_dirs}/g" "$INSTALL_TEMP_DIR/hadoop/yarn/etc/yarn-site.xml"
  sed -i "s/YARN_NODEMANAGER_LOG_DIRS_REPLACE/${escape_yarn_nodemanager_log_dirs}/g" "$INSTALL_TEMP_DIR/hadoop/yarn/etc/yarn-site.xml"
  sed -i "s/YARN_ZK_ADDRESS_REPLACE/${YARN_ZK_ADDRESS}/g" "$INSTALL_TEMP_DIR/hadoop/yarn/etc/yarn-site.xml"
  sed -i "s/YARN_KEYTAB_LOCATION_REPLACE/${YARN_KEYTAB_LOCATION}/g" "$INSTALL_TEMP_DIR/hadoop/yarn/etc/yarn-site.xml"
  sed -i "s/HTTP_KEYTAB_LOCATION_REPLACE/${HTTP_KEYTAB_LOCATION}/g" "$INSTALL_TEMP_DIR/hadoop/yarn/etc/yarn-site.xml"
  sed -i "s/YARN_TIMELINE_SERVICE_LEVELDB_STATE_STORE_PATH_REPLACE/${YARN_TIMELINE_SERVICE_LEVELDB_STATE_STORE_PATH}/g" "$INSTALL_TEMP_DIR/hadoop/yarn/etc/yarn-site.xml"
  sed -i "s/CALICO_NETWORK_NAME_REPLACE/${CALICO_NETWORK_NAME}/g" "$INSTALL_TEMP_DIR/hadoop/yarn/etc/yarn-site.xml"

  sed -i "s/YARN_RESOURCEMANAGER_NODES_EXCLUDE_PATH_REPLACE/${YARN_RESOURCEMANAGER_NODES_EXCLUDE_PATH}/g" "$INSTALL_TEMP_DIR/hadoop/yarn/etc/yarn-site.xml"
  mkdir -P "${YARN_RESOURCEMANAGER_NODES_EXCLUDE_PATH}"
  chmod 777 "${YARN_RESOURCEMANAGER_NODES_EXCLUDE_PATH}"

  # mapred-site.xml
  sed -i "s/YARN_NODEMANAGER_RECOVERY_DIR_REPLACE/${YARN_NODEMANAGER_RECOVERY_DIR}/g" "$INSTALL_TEMP_DIR/hadoop/yarn/etc/mapred-site.xml"
  mkdir -P "${YARN_NODEMANAGER_RECOVERY_DIR}"
  chmod 777 "${YARN_NODEMANAGER_RECOVERY_DIR}"

  sed -i "s/YARN_APP_MAPREDUCE_AM_STAGING_DIR_REPLACE/${YARN_APP_MAPREDUCE_AM_STAGING_DIR}/g" "$INSTALL_TEMP_DIR/hadoop/yarn/etc/mapred-site.xml"
  index=$(indexByRMHosts "${LOCAL_HOST_IP}")
  if [ -n "$index" ]; then
    # Only RM needs to execute the following code
    echo "Create hdfs path ${YARN_APP_MAPREDUCE_AM_STAGING_DIR}"
    "${HADOOP_HOME}/bin/hadoop" dfs -mkdir -p "${YARN_APP_MAPREDUCE_AM_STAGING_DIR}"
    "${HADOOP_HOME}/bin/hadoop" dfs chown yarn:hadoop "${YARN_APP_MAPREDUCE_AM_STAGING_DIR}"
    "${HADOOP_HOME}/bin/hadoop" dfs -chmod 1777 "${YARN_APP_MAPREDUCE_AM_STAGING_DIR}"
  fi

  # core-site.xml
  sed -i "s/LOCAL_REALM_REPLACE/${LOCAL_REALM}/g" "$INSTALL_TEMP_DIR/hadoop/yarn/etc/core-site.xml"
  sed -i "s/FS_DEFAULTFS_REPLACE/${FS_DEFAULTFS}/g" "$INSTALL_TEMP_DIR/hadoop/yarn/etc/core-site.xml"
  sed -i "s/HTTP_KEYTAB_LOCATION_REPLACE/${HTTP_KEYTAB_LOCATION}/g" "$INSTALL_TEMP_DIR/hadoop/yarn/etc/core-site.xml"
}

function install_spark_suffle() {
  cp -R "${PACKAGE_DIR}/hadoop/yarn/lib/*" "${HADOOP_HOME}/share/hadoop/yarn/lib/"
}

function install_mapred() {
  sed -i "s/MAPRED_KEYTAB_LOCATION_REPLACE/${MAPRED_KEYTAB_LOCATION}/g" "$INSTALL_TEMP_DIR/hadoop/yarn/etc/mapred-site.xml"
}

function install_yarn_sbin() {
  cp -R "${PACKAGE_DIR}/hadoop/yarn/sbin/*" "${HADOOP_HOME}/sbin/"

  sed -i "s/YARN_GC_LOG_DIR_REPLACE/${YARN_GC_LOG_DIR}/g" "${PACKAGE_DIR}/hadoop/yarn/conf/yarn-env.sh"
  cp -R "${PACKAGE_DIR}/hadoop/yarn/conf/yarn-env.sh" "${HADOOP_HOME}/conf/"

  sed -i "s/YARN_GC_LOG_DIR_REPLACE/${YARN_GC_LOG_DIR}/g" "${PACKAGE_DIR}/hadoop/yarn/conf/mapred-env.sh"
  cp -R "${PACKAGE_DIR}/hadoop/yarn/conf/mapred-env.sh" "${HADOOP_HOME}/conf/"

cat<<HELPINFO
You can use the start/stop script in the ${HADOOP_HOME}/sbin/ directory to start or stop the various services of the yarn.
HELPINFO
}

function install_yarn_service() {
  # WARN: ${HADOOP_HTTP_AUTHENTICATION_SIGNATURE_SECRET_FILE} Can not be empty!
  echo 'hello submarine' > "${HADOOP_HTTP_AUTHENTICATION_SIGNATURE_SECRET_FILE}"
  sed -i "s/HADOOP_HTTP_AUTHENTICATION_SIGNATURE_SECRET_FILE_REPLACE/${HADOOP_HTTP_AUTHENTICATION_SIGNATURE_SECRET_FILE}/g" "$INSTALL_TEMP_DIR/hadoop/yarn/etc/core-site.xml"

cat<<HELPINFO
You also need to set the yarn user to be a proxyable user, 
otherwise you will not be able to get the status of the service. 
Modify method: In core-site.xml, add parameters:
-----------------------------------------------------------------
<property>
<name>hadoop.proxyuser.yarn.hosts</name>
<value>*</value>
</property>
<property>
<name>hadoop.proxyuser.yarn.groups</name>
<value>*</value>
</property>
-----------------------------------------------------------------
HELPINFO
}

function install_registery_dns() {
  sed -i "s/YARN_REGISTRY_DNS_HOST_REPLACE/${YARN_REGISTRY_DNS_HOST}/g" "$INSTALL_TEMP_DIR/hadoop/yarn/etc/yarn-site.xml"
  sed -i "s/YARN_REGISTRY_DNS_HOST_PORT_REPLACE/${YARN_REGISTRY_DNS_HOST_PORT}/g" "$INSTALL_TEMP_DIR/hadoop/yarn/etc/yarn-site.xml"
}

function install_job_history() {
  sed -i "s/YARN_JOB_HISTORY_HOST_REPLACE/${YARN_JOB_HISTORY_HOST}/g" "$INSTALL_TEMP_DIR/hadoop/yarn/etc/mapred-site.xml"
}

## @description  install yarn timeline server
## @audience     public
## @stability    stable
## http://hadoop.apache.org/docs/r3.1.0/hadoop-yarn/hadoop-yarn-site/TimelineServer.html
function install_timeline_server()
{
  # set leveldb configuration
  sed -i "s/YARN_KEYTAB_LOCATION_REPLACE/${YARN_KEYTAB_LOCATION}/g" "$INSTALL_TEMP_DIR/hadoop/yarn/etc/yarn-site.xml"
  sed -i "s/YARN_AGGREGATED_LOG_DIR_REPLACE/${YARN_AGGREGATED_LOG_DIR}/g" "$INSTALL_TEMP_DIR/hadoop/yarn/etc/yarn-site.xml"
  sed -i "s/YARN_TIMELINE_SERVICE_HBASE_COPROCESSOR_LOCATION_REPLACE/${YARN_TIMELINE_SERVICE_HBASE_COPROCESSOR_LOCATION}/g" "$INSTALL_TEMP_DIR/hadoop/yarn/etc/yarn-site.xml"
  sed -i "s/YARN_TIMELINE_SERVICE_HBASE_CONFIGURATION_FILE_REPLACE/${YARN_TIMELINE_SERVICE_HBASE_CONFIGURATION_FILE}/g" "$INSTALL_TEMP_DIR/hadoop/yarn/etc/yarn-site.xml"

if [ "x$YARN_TIMELINE_HOST" != "x$LOCAL_HOST_IP" ]; then
  return 0
fi

  echo "install yarn timeline server V1.5 ..."

cat<<HELPINFO
Create '${YARN_AGGREGATED_LOG_DIR}' path on hdfs, Owner is 'yarn', group is 'hadoop', 
and 'hadoop' group needs to include 'hdfs, yarn, mapred' yarn-site.xml users, etc.
HELPINFO
  "${HADOOP_HOME}/bin/hadoop" dfs -mkdir -p "${YARN_AGGREGATED_LOG_DIR}"
  "${HADOOP_HOME}/bin/hadoop" dfs chown yarn:hadoop "${YARN_AGGREGATED_LOG_DIR}"
  "${HADOOP_HOME}/bin/hadoop" dfs -chmod 1777 "${YARN_AGGREGATED_LOG_DIR}"

  # yarn.timeline-service.entity-group-fs-store.active-dir in yarn-site.xml
  "${HADOOP_HOME}/bin/hadoop" dfs -mkdir -p /tmp/submarine-entity-file-history/active
  "${HADOOP_HOME}/bin/hadoop" dfs chown yarn:hadoop "${YARN_AGGREGATED_LOG_DIR}"
  "${HADOOP_HOME}/bin/hadoop" dfs -chmod 01777 /tmp/submarine-entity-file-history/active

  # yarn.timeline-service.entity-group-fs-store.done-dir in yarn-site.xml
  "${HADOOP_HOME}/bin/hadoop" dfs -mkdir -p /tmp/submarine-entity-file-history/done
  "${HADOOP_HOME}/bin/hadoop" dfs chown yarn:hadoop "${YARN_AGGREGATED_LOG_DIR}"
  "${HADOOP_HOME}/bin/hadoop" dfs -chmod 0700 /tmp/submarine-entity-file-history/done

  ## install yarn timeline server V2
  echo "install yarn timeline server V2 ..."

cat<<HELPINFO
1. Use the hbase shell as the hbase user to authorize the yarn, HTTP user:
> grant 'yarn', 'RWC'
> grant 'HTTP', 'R'
HELPINFO
  read -p "Do you done the above operation[Y/N]?" answer
  case $answer in
  Y | y)
    echo "Continue installing ...";;
  N | n)
    echo "Stop installing the timeline server V2";;
    return(0);
  *)
    echo "Stop installing the timeline server V2";;
    return(0);
  esac

  "${HADOOP_HOME}/bin/hadoop" fs -mkdir "${HBASE_COPROCESSOR_LOCATION}/"
  "${HADOOP_HOME}/bin/hadoop" fs -chmod -R 755 "${HBASE_COPROCESSOR_LOCATION}/"
  "${HADOOP_HOME}/bin/hadoop" fs -put "${HADOOP_HOME}/share/hadoop/yarn/timelineservice/hadoop-yarn-server-timelineservice-hbase-coprocessor-3.*.jar" "${HBASE_COPROCESSOR_LOCATION}/hadoop-yarn-server-timelineservice.jar"

cat<<HELPINFO
2. Copy the timeline hbase jar to the <hbase_client>/lib path:
HELPINFO

  cp "${HADOOP_HOME}/share/hadoop/yarn/timelineservice/hadoop-yarn-server-timelineservice-hbase-common-3.*-SNAPSHOT.jar" "${HBASE_HOME}/lib"
  cp "${HADOOP_HOME}/share/hadoop/yarn/timelineservice/hadoop-yarn-server-timelineservice-hbase-client-3.*-SNAPSHOT.jar" "${HBASE_HOME}/lib"

cat<<HELPINFO
3. In the hbase server, After using the keytab authentication of yarn, 
In the <hbase_client> path, Execute the following command to create a schema
> bin/hbase org.apache.hadoop.yarn.server.timelineservice.storage.TimelineSchemaCreator -create
HELPINFO
}
