# Nagios-FTP-monitoing

First of all you need to install Nagios core 4.2.0. Its an open source and available for free.

Configuration file mostly resides at /usr/local/nagios/etc

Once you are decided with config file attributes then you can use tool addhostnagios.sh to add/delete host/hostgroups automatically. User is not required to manually edit/add configuration. Since its the responsiblity of tool to add or delete configration,  so the configuration remains consistent and error free. This tool helps most when your config size increases. 

How to use it?

host#./addhostnagios.sh

***  You have below options to select.

** 1: Add host or hosts to existing Cluster.
** 2: Remove host or hosts from existing Cluster.
** 3: Add a new cluster to nagios monitoring.
** 4: Remove an existing cluster from nagios monitoring.

** Select your option number:[1-4]:
>> Your Selection:>>3

** Below clusters are available under nagios at present.

xyz_Cluster
zxr_Cluster
llk_Storage
ikj_Cluster
nlj_Cluster


** Enter new cluster name.
>> Your Selection:>>new_Cluster

** Enter host names with coma seprated.Example ==> host1.corp.xyz.com,host2.corp.xyz.com
>> Your Selection:>>host1.corp.xyz.com,host2.corp.xyz.com,host3.corp.xyz.com,host4.corp.xyz.com,host5.corp.xyz.com,host6.corp.xyz.com

Success:Cluster added to config.

================================================

./addhostnagios.sh

***  You have below options to select.

** 1: Add host or hosts to existing Cluster.
** 2: Remove host or hosts from existing Cluster.
** 3: Add a new cluster to nagios monitoring.
** 4: Remove an existing cluster from nagios monitoring.

** Select your option number:[1-4]:
>> Your Selection:>>2

** You can remove host or hosts from below clusters.

xyz_Cluster
zxr_Cluster
llk_Storage
ikj_Cluster
nlj_Cluster
new_Cluster

** Enter the cluster name to list host:
>> Your Selection:>>Indvault_Cluster

host6.corp.xyz.com

** Enter host names with coma seprated.Example ==> host1.corp.xyz.com,host2.corp.xyz.com
>> Your Selection:>>host6.corp.xyz.com

Success:Host entry removed. ==> host6.corp.xyz.com

simlarly you can choose other options for adding host/removing hosts.


