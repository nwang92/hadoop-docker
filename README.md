# README #

### Hadoop in Docker ###

**Quick summary:** This repo contains docker images/compose files and Ansible playbooks for running multi-vendor Hadoop products through Docker.

### Getting Started ###

```
#!bash

# To bring up a Hortonworks Ambari stack
# Default Ambari credentials: admin/admin
$ docker-compose up -d hortonworks/ambari.yml
$ ansible-playbook -i <comma-separated list of container names> -c docker hortonworks/provision_ambari.yml

# To bring up a Cloudera CDH stack
# Default CDH credentials: admin/admin
$ docker-compose up -d cloudera/cdh.yml
$ ansible-playbook -i <comma-separated list of container names> -c docker cloudera/provision_cdh.yml

# To bring up a MAPR stack
# Default CDH credentials: root/hello
$ docker-compose up -d mapr/mapr.yml
$ ansible-playbook -i <comma-separated list of container names> -c docker mapr/provision_mapr.yml
```

### How it Works ###

For all of the vendors, the base docker images for each provider have all the necessary packages to bring up traditional Hadoop services. Ansible is used post-container-creation to run provisioning, which can entail pulling additional services (Hive, Sqoop, etc.) to augment your Hadoop cluster. This also provides some flexibility in that you can add more agents/nodes by adding a new block with the appropriate role in the applicable docker-compose file.

For both Hortonworks/Ambari + Cloudera/CDH, the general Hadoop setup will be performed via the traditional "server + agents" template. To simplify the docker images/services template, there will be one single image that can act as either server/agent, and it is the command used during bring-up that determines it's role.

Servers are responsible for holding cluster configurations, cluster blueprints, host-group mappings. In addition to that, the server is responsible for setting up the entire Hadoop cluster with the services required (or needed, as defined by users). Once a cluster has been configured, the server is able to view dashboards and gather information about the cluster, but it itself is not part of the cluster. Additionally, for any given deployment, there should only exist 1 server.

Agents are the actual nodes that get bootstrapped by the server and have active roles in the Hadoop cluster. The agents are configured to communicate with the server via ansible plays. After that, commands are sent to the server to download/install the respective services. Agents can be further subdivided into roles within a cluster: generally, master nodes and slave nodes (or a secondary master for HA). For ease of deployment, the ansible playbook randomly selects one of the agents to be a master, while the rest are slaves. Additionally, for any given deployment, there should be at least 2 agents (1 master, 1 slave).

For MAPR, the "server + agents" structure is not part of their installation model. Instead, since there is no centralized configuration server, each node brought up in the additional services will be part of the cluster. To simplify the process, every node will have the same image + MAPR dependencies pre-installed, and it will simply be a matter of configuring which node is the "master" (in MAPR terminology, these will be the CLDBs/Zookeepers/etc.)and which nodes are "slaves" (in MAPR terminology, the ResourceManagers/clients/etc.). 

### Hadoop Configuration ###

**Hortonworks/Ambari**
1) To install specific services on the Hadoop cluster, modify the components listed in templates/ambari_config.json. Components installed under "masters" will get installed on the master node, and same with "slaves".
2) For more complex Hadoop topologies (ex: secondary master for HA), you can modify the templates/ambari_hosts.json to create a new hosts group for the new role, then add components to that role in templates/ambari_config.json.
3) To bring up additional Ambari nodes for a larger deployments + clusters, modify the ambari.yml docker-compose file. Follow the existing template to add a new node, and make sure it is configured to run as an agent (command: agent).

For Hortonworks/Ambari, it is required to use 1 server role and a minimum of 2 agent roles. Using the same services template, The follow Hadoop services will be available with each of the following ports:

* Ambari Server: http://server:8080
* NameNode: http://node1:50070
* ResourceManager: http://node1:8088
* JobHistory: http://node1:19888
* Graphana: http://node1:3000
* DataNode: http://node[2:]:50075 (DataNode will be available on all nodes except node1)

**Cloudera/CDH**
1) To install specific services on the Hadoop cluster, modify the components listed in templates/cdh_config.json. Components installed under "master-nodes" will get installed on the master node, and same with "slave-nodes".
2) To enable/disable monitoring of the Cloudera cluster, see templates/cms.json and the provision_cdh.yml Ansible playbook. The cms.json is a configuration file to setup Cloudera Monitoring Service, which includes Service Monitoring, Host Monitoring, Alarms/Events and more. You can modify this template file based on which monitoring services you need. Additionally, you can disable all monitoring by removing the POST request in the provision_cdh.yml Ansible playbook.
3) To bring up additional CDH nodes for a larger deployments + clusters, modify the cdh.yml docker-compose file. Follow the existing template to add a new node, and make sure it is configured to run as an agent (command: agent) with a distinct hostname (hostname: nodeN).

For Cloudera/CDH, it is required to use 1 server role and a minimum of 2 agent roles. Using the same services template, The follow Hadoop services will be available with each of the following ports:

* Cloudera Manager Server: http://server:7180
* NodeManager: http://node1:50070
* ResourceManager: http://node1:8088
* JobHistory: http://node1:19888
* DataNode: http://node[2:]:50075 (DataNode will be available on all nodes except node1)

All other Cloudera Management services will be hosted on node2, hence the requirement for at least 2 nodes.

**MAPR**
1) To bring up additional MAPR nodes for a larger deployments + clusters, modify the mapr.yml docker-compose file. Follow the existing template to add a new node, and make sure it is configured to run with a distinct hostname (hostname: nodeN).

### Guides/Important Links ###

Hortonworks/Ambari:
* https://docs.hortonworks.com/HDPDocuments/Ambari-2.5.1.0/bk_ambari-installation/content/install-ambari-server-ubuntu16.html
* https://cwiki.apache.org/confluence/display/AMBARI/Installation+Guide+for+Ambari+2.5.1
* https://www.ibm.com/support/knowledgecenter/en/SSCVHB_1.2.0/admin/tnpi_start_stop_ambari_server.html
* https://ambari.apache.org/1.2.3/installing-hadoop-using-ambari/content/ambari-chap9-3.html
* http://jesseyates.com/2015/10/26/choosing-ambari.html
* https://ambari.apache.org/1.2.0/installing-hadoop-using-ambari/content/ambari-chap6-1.html
* https://github.com/sequenceiq/docker-ambari
* https://github.com/dwatrous/hadoop-multi-server-ansible
* https://github.com/inspur-docker/ambari-docker
* https://cwiki.apache.org/confluence/display/AMBARI/Blueprints#Blueprints-Step1:CreateBlueprint
* https://community.hortonworks.com/questions/83437/ambari-export-blueprint.html
* https://cwiki.apache.org/confluence/display/AMBARI/Blueprints#Blueprints-CreateClusterInstance
* https://community.hortonworks.com/articles/61358/automate-hdp-installation-using-ambari-blueprints-2.html

Cloudera/CDH:
* https://github.com/chali/hadoop-cdh-pseudo-docker/blob/master/Dockerfile
* https://github.com/lucamilanesio/docker-cdh5.4/blob/master/docker_files/cdh_centos_installer.sh
* http://www.cloudera.com/documentation/cdh/5-0-x/CDH5-Installation-Guide/cdh5ig_cdh5_install.html?scroll=topic_4_4_1_unique_1__section_dfx_p51_nj_unique_1
* https://www.cloudera.com/documentation/enterprise/5-4-x/topics/cm_ig_install_path_b.html
* http://blog.cloudera.com/blog/2013/07/how-does-cloudera-manager-work/
* https://github.com/cloudera/cloudera-playbook

MAPR:
* http://doc.mapr.com/display/MapR/Advanced+Installation+Topics
* http://doc.mapr.com/display/MapR/configure.sh
* http://doc.mapr.com/display/MapR/Ports+Used+by+MapR
* http://doc.mapr.com/display/MapR/Adding+Roles+to+a+Node
* http://doc.mapr.com/display/MapR/Removing+Roles+from+a+Node
* http://doc.mapr.com/display/MapR/Setting+Up+MapR+NFS
