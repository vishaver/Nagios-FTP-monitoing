#!/bin/bash

tput setaf 6
menu ()
     {
     echo " "
     echo "***  You have below options to select."
     echo " "
     echo "** 1: Add host or hosts to existing Cluster."
     echo "** 2: Remove host or hosts from existing Cluster."
     echo "** 3: Add a new cluster to nagios monitoring."
     echo "** 4: Remove an existing cluster from nagios monitoring."
     echo " "
     echo  "** Select your option number:[1-4]:"
     tput setaf 3
     read -p ">> Your Selection:>>" selection
     tput sgr0
     }
menu


if [[ -n ${selection//[0-9]/} ]]
   then
       tput setaf 1
       echo "Error:Non Numeric input.Please enter any option from [1-4]."
       echo " "
       tput sgr0
       exit 1
fi

if [[ $selection -gt 4 ]]
  then
     tput setaf 1
     echo "Error:You entered invalid option.Please enter any option in range 1-4]."
     echo " "
     tput sgr0
     exit 1
fi

hostFqdnCheck  ()
 {
for line in `echo $hostName | tr ',' '\n'`
        do
        fqdnCheck=$(echo $line | grep -E "xyx.com" &> /dev/null;echo $?)
        if [[ $fqdnCheck -ne 0 ]]
           then
               array1[$checkArray]=1
               tput setaf 1
               echo "Error:Either host name is incorrect or full fqdn not provided.Please try again. Host ==> $line"
               tput sgr0
               let "checkArray=checkArray+1"
               break
           else
              array1[$checkArray]=0
              let "checkArray=checkArray+1"
        fi
        done
        array1Sum=$(echo ${array1[@]} | tr ' ' '\n' | awk '{ sum+=$1} END {print sum}')
        if [[ $array1Sum -gt 0 ]]
           then
               echo " "
               exit 1
        fi
}

clusterAvailCheck ()
        {
        clusterCheck=$(cat /usr/local/nagios/etc/ftp.cfg | grep "hostgroup_name" | awk '{print $2}' | sort -u | grep -w "^$clusterName$" &> /dev/null;echo $?)
        if [[ $clusterCheck -ne 0 ]]
             then
                 echo " "
                 tput setaf 1
                 echo "Error:Cluster Name you provided is not listed in configuration file.Plese check nagios Host Groups Summary section."
                 tput sgr0
                 echo " "
                 exit 1
        fi
        }

addHost ()
        {
        echo " "
        clusterAvailable=$(cat /usr/local/nagios/etc/ftp.cfg | grep "hostgroup_name" | awk '{print $2}' | sort -u  | paste -d"|" -s -)
        tput setaf 6
        echo "** You can add host to below clusters."
        echo " "
        echo $clusterAvailable | tr '|' '\n'
        echo " "
        echo "** Enter the cluster name.:"
        tput setaf 3
        read -p ">> Your Selection:>>" clusterName
        clusterAvailCheck
        echo " "
        tput setaf 6
        echo "** Selected cluster contains below hosts."
        echo " "
        cat /usr/local/nagios/etc/ftp.cfg | grep -E -A3 "$clusterName"  | grep -E "members" | awk '{print $2}' | tr ',' '\n'
        echo " "
        echo "** Enter host names with coma seprated.Example ==> host1.corp.xyz.com,host2.corp.xyz.com"
        tput setaf 3
        read -p ">> Your Selection:>>" hostName
        echo " "
        tput sgr0
        checkArray=1
        hostFqdnCheck
        echo $hostName | tr ',' '\n' | sort -u | while read line
        do
        hostAlive $line
        done
        }

removeHost ()
        {
        echo " "
        clusterAvailable=$(cat /usr/local/nagios/etc/ftp.cfg | grep "hostgroup_name" | awk '{print $2}' | sort -u  | paste -d"|" -s -)
        tput setaf 6
        echo "** You can remove host or hosts from below clusters."
        echo " "
        echo $clusterAvailable | tr '|' '\n'
        echo " "
        echo "** Enter the cluster name to list host:"
        tput setaf 3
        read -p ">> Your Selection:>>" clusterName
        echo " "
        tput setaf 6
        cat /usr/local/nagios/etc/ftp.cfg | grep -E -A3 "$clusterName"  | grep -E "members" | awk '{print $2}' | tr ',' '\n'
        echo " "
        echo "** Enter host names with coma seprated.Example ==> host1.corp.xyz.com,host2.corp.xyz.com"
        tput setaf 3
        read -p ">> Your Selection:>>" hostName
        tput sgr0
        echo " "
        checkArray=1

        hostFqdnCheck

        echo $hostName | tr ',' '\n' | sort -u | while read line
        do
        checkAndRemoveHost
        done
        /usr/local/nagios/bin/nagios -v /usr/local/nagios/etc/nagios.cfg  &> /dev/null
        sleep 2
        /etc/init.d/nagios reload &> /dev/null
        sleep 2
        }

checkAndRemoveHost ()
         {
         getHostNames=$(cat /usr/local/nagios/etc/ftp.cfg | grep -E "host_name" | awk '{print $2}')
         hostFound=$(echo $getHostNames | tr ' ' '\n' | grep -w "^$line$" &> /dev/null;echo $?)
         if [[ $hostFound -ne 0 ]]
            then
                tput setaf 1
                echo "Error:This host is not found in configuration ==> $line"
                tput sgr0
                break
            else
                gethostLine=$(cat /usr/local/nagios/etc/ftp.cfg | grep -n "$line" | grep -E "host_name" | awk -F: '{print $1}')
                delStart=$(echo $gethostLine - 2 | bc)
                delStop=$(echo $gethostLine + 4 | bc)
                cat /usr/local/nagios/etc/ftp.cfg | sed ''$delStart','$delStop'd' > /usr/local/nagios/etc/ftp_config_change.cfg
                mv /usr/local/nagios/etc/ftp_config_change.cfg /usr/local/nagios/etc/ftp.cfg
                hostGroupMembers=$(cat /usr/local/nagios/etc/ftp.cfg | grep -E "$line" | grep -E "members" | awk '{print $2}')
                hostGroupMembersNew=$(echo $hostGroupMembers | tr ',' '\n' | sed 's/'$line'//g' | grep -v "^$" | paste -d"," -s -)
                if [[ -z $hostGroupMembersNew ]]
                   then
                       hostGroupDel=$(cat /usr/local/nagios/etc/ftp.cfg | grep -n "$line" | grep -E "members" | awk -F: '{print $1}')
                       hostGroupDelStart=$(echo $hostGroupDel - 3 | bc)
                       hostGroupDelStop=$(echo $hostGroupDel + 1 | bc)
                       cat /usr/local/nagios/etc/ftp.cfg | sed ''$hostGroupDelStart','$hostGroupDelStop'd' > /usr/local/nagios/etc/ftp_config_change.cfg
                       mv -f /usr/local/nagios/etc/ftp_config_change.cfg /usr/local/nagios/etc/ftp.cfg

                       hostServiceDel=$(cat /usr/local/nagios/etc/ftp.cfg | grep -n "$clusterName" | grep -E "hostgroup_name" | awk -F: '{print $1}')
                       hostServiceDelStart=$(echo $hostServiceDel - 2 | bc)
                       hostServiceDelStop=$(echo $hostServiceDel + 3 | bc)
                       cat /usr/local/nagios/etc/ftp.cfg | sed ''$hostServiceDelStart','$hostServiceDelStop'd' > /usr/local/nagios/etc/ftp_config_change.cfg
                       mv -f /usr/local/nagios/etc/ftp_config_change.cfg /usr/local/nagios/etc/ftp.cfg
                   else
                       cat /usr/local/nagios/etc/ftp.cfg | sed 's/'$hostGroupMembers'/'$hostGroupMembersNew'/g' > /usr/local/nagios/etc/ftp_config_change.cfg
                       mv -f /usr/local/nagios/etc/ftp_config_change.cfg /usr/local/nagios/etc/ftp.cfg &> /dev/null
                fi
                tput setaf 2
                echo "Success:Host entry removed. ==> $line"
                tput sgr0
         fi
         }

hostAlive ()
        {
         pingStats=$(ping -c 2 $1 &> /dev/null;echo $?)
         if [[ $pingStats -eq 0 ]]
            then
                ipAddress=$(host $1 | awk '{print $NF}')
                hostname=$1
                aliasName=$(echo $1 | cut -d'.' -f1 | python -c "print raw_input().capitalize()")
                checkHost=$(cat /usr/local/nagios/etc/ftp.cfg | grep -E "host_name" | awk '{print $2}' | grep -w "^$hostname$" &> /dev/null ;echo $?)
                if [[ $checkHost -ne 0 ]]
                   then
                       hostCreate
                       if [[ $selection -eq 1 ]]
                          then
                              olderGroupmemberwithoutUniq=$(cat /usr/local/nagios/etc/ftp.cfg | grep -E -A 4 "$clusterName" | grep -E "members"  | awk '{print $2}' | paste -d"," -s -)
                              olderGroupmemberswithUniq=$(echo $olderGroupmemberwithoutUniq | tr ',' '\n' | sort -u | paste -d"," -s -)
                              newmembers=$(echo "$olderGroupmemberswithUniq,$hostname" | tr ',' '\n' | sort -u | paste -d"," -s -)
                              cat /usr/local/nagios/etc/ftp.cfg | sed 's/'$olderGroupmemberwithoutUniq'/'$newmembers'/g' > /usr/local/nagios/etc/ftp_config_change.cfg
                              mv /usr/local/nagios/etc/ftp_config_change.cfg /usr/local/nagios/etc/ftp.cfg &> /dev/null
                              /usr/local/nagios/bin/nagios -v /usr/local/nagios/etc/nagios.cfg &> /dev/null
                              /etc/init.d/nagios reload  &> /dev/null
                              tput setaf 2
                              echo "Success:Host entry created. ==> $hostname"
                              tput sgr0
                         elif [[ $selection -eq 3 ]]
                              then
                                  true
                       fi
                   else
                       tput setaf 3
                       echo "Info:Host already present. ==> $hostname"
                       tput sgr0
                fi
              else
                  echo " "
                  tput setaf 1
                  echo "Error:Host not pingable. ==> $1"
                  tput sgr0
                  exit 1

         fi
        }

addCluster ()
        {
        echo " "
        tput setaf 6
        echo "** Below clusters are available under nagios at present."
        clusterAvailable=$(cat /usr/local/nagios/etc/ftp.cfg | grep "hostgroup_name" | awk '{print $2}' | sort -u  | paste -d"|" -s -)
        echo " "
        echo $clusterAvailable | tr '|' '\n'
        echo " "
        tput setaf 6
        echo "** Enter new cluster name."
        tput setaf 3
        read -p ">> Your Selection:>>" clusterName
        tput sgr0
        clusterCheck=$(cat /usr/local/nagios/etc/ftp.cfg | grep "hostgroup_name" | awk '{print $2}' | sort -u | grep -w "^$clusterName$" &> /dev/null;echo $?)
        if [[ $clusterCheck -eq 0 ]]
             then
                 echo " "
                 tput setaf 1
                 echo "Error:Cluster name you provided is already present.Plese use option 1 to add host to this cluster."
                 tput sgr0
                 echo " "
                 exit 1
        fi
        echo " "
        tput setaf 6
        echo "** Enter host names with coma seprated.Example ==> host1.corp.xyz.com,host2.corp.xyz.com"
        tput setaf 3
        read -p ">> Your Selection:>>" hostName
        echo " "
        tput sgr0
        checkArray=1
        hostFqdnCheck
        echo $hostName | tr ',' '\n' | sort -u | while read line
        do
        hostAlive $line
        done
        pingableHost=$(echo $hostName | tr ',' '\n' | while read line
        do
          pingStats=$(ping -c 2 $line &> /dev/null;echo $?)
          if [[ $pingStats -eq 0 ]]
             then
                 echo $line
          fi
        done | paste -d"," -s -)
        if [[ -z $pingableHost ]]
           then
               exit 1
        fi
        hostGroupCreate
        serviceCreate
        /usr/local/nagios/bin/nagios -v /usr/local/nagios/etc/nagios.cfg &> /dev/null
        /etc/init.d/nagios reload &> /dev/null
        tput setaf 2
        echo "Success:Cluster added to config."
        tput sgr0
        }

removeCluster ()
          {
           clusterAvailable=$(cat /usr/local/nagios/etc/ftp.cfg | grep "hostgroup_name" | awk '{print $2}' | sort -u  | paste -d"|" -s -)
           tput setaf 6
           echo "** Enter new cluster name to delete. Curent available clusters are:"
           echo " "
           echo $clusterAvailable | tr '|' '\n'
           echo " "
           tput setaf 3
           read -p ">> Your Selection:" clusterName
           tput sgr0
           clusterAvailCheck
           hostGroupFind=$(cat /usr/local/nagios/etc/ftp.cfg  | grep -n "$clusterName" | grep -E "hostgroup_name"| head -1 |  awk -F: '{print $1}')
           hgrpStart=$(echo $hostGroupFind - 2 | bc)
           hgrpStop=$(echo $hostGroupFind + 3 | bc)
           hostMembers=$(cat /usr/local/nagios/etc/ftp.cfg | sed -n "$hgrpStart","$hgrpStop"p | grep -E "members" | awk '{print $2}')
           echo $hostMembers | tr ',' '\n' | sort -u | while read line
           do
           checkAndRemoveHost
           done
           /usr/local/nagios/bin/nagios -v /usr/local/nagios/etc/nagios.cfg &> /dev/null
           /etc/init.d/nagios reload &> /dev/null
           tput setaf 2
           echo "Success:Cluster removed from config."
           tput sgr0
          }
hostCreate ()
             {
             hostEntryCreate=$(echo "define host{
                                                use             ftp-server
                                                host_name       $hostname
                                                alias           $aliasName
                                                address         $ipAddress
                                                hostgroups      $clusterName
                                                }")
            echo $hostEntryCreate | tr ' ' '\n' | paste -d" " - - >> /usr/local/nagios/etc/ftp.cfg
            }

function hostGroupCreate
            {
            hostGroupEntryCreate=$(echo "define hostgroup{
                                                 hostgroup_name $clusterName
                                                 alias          FTP_Storage_Nodes
                                                 members        $pingableHost
                                                        }")
            echo $hostGroupEntryCreate | tr ' ' '\n' | paste -d" " - - >> /usr/local/nagios/etc/ftp.cfg
            }


function serviceCreate
         {
          serviceEntryCreate=$(echo "define service{
                                                   use                     ftp-service
                                                   hostgroup_name          $clusterName
                                                   service_description     FTP_CHECK
                                                   check_command           'check_ftp_rw!username!password'
                                                   }")
         echo $serviceEntryCreate| sed "s/'//g" | tr ' ' '\n' | paste -d" " - - >> /usr/local/nagios/etc/ftp.cfg
        }

if [[ $selection -eq 1 ]]
   then
       addHost
   elif [[ $selection -eq 2 ]]
       then
           removeHost
   elif [[ $selection -eq 3 ]]
       then
           addCluster
   elif [[ $selection -eq 4 ]]
       then
           removeCluster
fi
