#!/bin/bash
####first destroy all 5 nodes in parallel
cd  oci-arch-bmdb-ha-master/observer-one
terraform  destroy -force |tee /tmp/oracle_12201_observer-one_destroy.log  &
cd  oci-arch-bmdb-ha-master/observer-two
terraform  destroy -force |tee /tmp/oracle_12201_observer-two_destroy.log & 
cd  oci-arch-bmdb-ha-master/observer-three
terraform  destroy -force |tee /tmp/oracle_12201_observer-three_destroy.log &
cd  oci-arch-bmdb-ha-master/primary_db_system
terraform  destroy -force |tee /tmp/oracle_12201_primary_db_system_destroy.log &
cd  oci-arch-bmdb-ha-master/standby_db_system
terraform  destroy -force |tee /tmp/oracle_12201_standby_db_system_destroy.log &

###wait for all the destructions to complete
date
wait
date
echo "Done with all 5 destructions of 3 observer nodes and 2 database nodes"

cd  oci-arch-bmdb-ha-master/observer-one
terraform apply -auto-approve |tee /tmp/oracle_12201_observer-one_create.log &
cd  oci-arch-bmdb-ha-master/observer-two
terraform apply -auto-approve |tee /tmp/oracle_12201_observer-two_create.log &
cd  oci-arch-bmdb-ha-master/observer-three
terraform apply -auto-approve |tee /tmp/oracle_12201_observer-three_create.log&
cd  oci-arch-bmdb-ha-master/primary_db_system
terraform apply -auto-approve |tee /tmp/oracle_12201_primary_db_system_create.log &
cd  oci-arch-bmdb-ha-master/standby_db_system
terraform apply -auto-approve |tee /tmp/oracle_12201_standby_db_system_create.log &

###wait for all the creations to complete
date
wait
date
echo "Done with all 5 creations of 3 observer nodes and 2 database nodes"

cd oci-arch-bmdb-ha-master/primary_db_system
PRIMARY_DOMAIN_NAME=`cat terraform.tfvars|grep -i BM-DBNodeDomainName| awk -F "=" '{print $2}'|tr -d '"'|tr -d ' '`
echo $PRIMARY_DOMAIN_NAME
export PRIMARY_DOMAIN_NAME
PRIMARY_HOST_NAME=`cat terraform.tfvars|grep -i BM-DBNodeHostName| awk -F "=" '{print $2}'|tr -d '"'|tr -d ' '`
echo $PRIMARY_HOST_NAME
export PRIMARY_HOST_NAME
PRIMARY_PUBLIC_IP_ADDRESS=`terraform output "Public IP of the DB system-BM"`
echo $PRIMARY_PUBLIC_IP_ADDRESS
export PRIMARY_PUBLIC_IP_ADDRESS
echo $PRIMARY_PUBLIC_IP_ADDRESS ${PRIMARY_HOST_NAME}.${PRIMARY_DOMAIN_NAME}
echo $PRIMARY_PUBLIC_IP_ADDRESS ${PRIMARY_HOST_NAME}.${PRIMARY_DOMAIN_NAME} > my_primary_system_hostname_ip_details.txt
export PRIMARYARY_HOSTS=$(echo ${PRIMARY_PUBLIC_IP_ADDRESS} ${PRIMARY_HOST_NAME}.${PRIMARY_DOMAIN_NAME})
echo $PRIMARYARY_HOSTS


####get Standby system IP and hostname from Terraform from standby system creation

cd oci-arch-bmdb-ha-master/standby_db_system

STANDBY_DOMAIN_NAME=`cat terraform.tfvars|grep -i BM-DBNodeDomainName| awk -F "=" '{print $2}'|tr -d '"'|tr -d ' '`
echo $STANDBY_DOMAIN_NAME
STANDBY_HOST_NAME=`cat terraform.tfvars|grep -i BM-DBNodeHostName| awk -F "=" '{print $2}'|tr -d '"'|tr -d ' '`
echo $STANDBY_HOST_NAME
STANDBY_PUBLIC_IP_ADDRESS=`terraform output "Public IP of the DB system-BM"`
echo $STANDBY_PUBLIC_IP_ADDRESS
echo $STANDBY_PUBLIC_IP_ADDRESS  ${STANDBY_HOST_NAME}.${STANDBY_DOMAIN_NAME}
echo $STANDBY_PUBLIC_IP_ADDRESS  ${STANDBY_HOST_NAME}.${STANDBY_DOMAIN_NAME}>my_standby_system_hostname_ip_details.txt
export STANDBY_HOSTS=$(echo ${STANDBY_PUBLIC_IP_ADDRESS} ${STANDBY_HOST_NAME}.${STANDBY_DOMAIN_NAME})
echo $STANDBY_HOSTS

###add some sleep if ssh is not yet responding on standby_db_system
#sleep 600
ssh -o "StrictHostKeyChecking no" opc@$STANDBY_PUBLIC_IP_ADDRESS "sudo su - oracle" <<EOF 
date
EOF
flag=$?
while [ "$flag" != "0" ]
do
echo "I am sleeping now as standby not allowing ssh"
sleep 60
ssh -o "StrictHostKeyChecking no" opc@$STANDBY_PUBLIC_IP_ADDRESS "sudo su - oracle" <<EOF 
date
EOF
flag=$?
done
###add some sleep if ssh is not yet responding on sprimary_db_system
#sleep 600
ssh -o "StrictHostKeyChecking no" opc@$PRIMARY_PUBLIC_IP_ADDRESS "sudo su - oracle" <<EOF 
date
EOF
flag=$?
while [ "$flag" != "0" ]
do
echo "I am sleeping now as primary not allowing ssh"
sleep 60
ssh opc@$PRIMARY_PUBLIC_IP_ADDRESS "sudo su - oracle" <<EOF 
date
EOF
flag=$?
done
####get Primary system IP and hostname from Terraform from primary system creation

######set up primary by ssh and setup the bash_profile

ssh -o "StrictHostKeyChecking no" opc@$PRIMARY_PUBLIC_IP_ADDRESS "sudo su - oracle" <<'EOF' 
cat >>/home/oracle/.bash_profile <<EOFP
export ORACLE_HOME=/u01/app/oracle/product/12.2.0.1/dbhome_1
export ORACLE_SID=ORCL
export PATH=\$PATH:\$HOME/bin:\$ORACLE_HOME/bin
alias sp='sqlplus / as sysdba'
EOFP
EOF


####automation to get db_unique_name ######

ssh opc@$PRIMARY_PUBLIC_IP_ADDRESS "sudo su - oracle" <<'EOFC' >/tmp/db_unique_name.txt
sqlplus -s / as sysdba << EOF 
set echo off
set feed off
set veri off
set pagesize 32
set linesize 132
set head off
set pages 0
set escape on
select value from v\$parameter where name='db_unique_name';
EOF
EOFC


##keep db_unique_name.txt  in a variable called prim_db_unique_name

export PRIMARY_DB_UNIQUE_NAME=`cat /tmp/db_unique_name.txt`

echo $PRIMARY_DB_UNIQUE_NAME


####automation to get db_domain ######

ssh opc@$PRIMARY_PUBLIC_IP_ADDRESS "sudo su - oracle" <<'EOFC' >/tmp/db_domain.txt
sqlplus -s / as sysdba << EOF 
set echo off
set feed off
set veri off
set pagesize 32
set linesize 132
set head off
set pages 0
set escape on
select value from v\$parameter where name='db_domain';
EOF
EOFC


##keep db_domain.txt  in a variable called prim_db_domain

export PRIMARY_DB_DOMAIN_NAME=`cat /tmp/db_domain.txt`

echo $PRIMARY_DB_DOMAIN_NAME

#################################################################

####for tde to work correctly we need to set ORACLE_UNQNAME in the bash_profile for primary
ssh -o "StrictHostKeyChecking no" opc@$PRIMARY_PUBLIC_IP_ADDRESS "sudo su - oracle" <<EOF 
cat >>/home/oracle/.bash_profile <<EOFP
export ORACLE_UNQNAME=$PRIMARY_DB_UNIQUE_NAME
EOFP
EOF

#################################################################

####test to automate above ####   note usage of 'EOF' to keep escaping the heredoc securely


ssh opc@$PRIMARY_PUBLIC_IP_ADDRESS "sudo su - grid" <<EOF 
cat >>/u01/app/12.2.0.1/grid/network/admin/listener.ora <<EOFP
SID_LIST_LISTENER=
      (SID_LIST=
        (SID_DESC=
        (SDU=65535)
        (GLOBAL_DBNAME = ORCL_${PRIMARY_DB_UNIQUE_NAME}.${PRIMARY_DB_DOMAIN_NAME})
        (SID_NAME = ORCL)
        (ORACLE_HOME=/u01/app/oracle/product/12.2.0.1/dbhome_1)
        (ENVS="TNS_ADMIN=c")
        )
        (SID_DESC=
        (SDU=65535)
        (GLOBAL_DBNAME = ORCL_${PRIMARY_DB_UNIQUE_NAME}_DGMGRL.${PRIMARY_DB_DOMAIN_NAME})
        (SID_NAME = ORCL)
        (ORACLE_HOME=/u01/app/oracle/product/12.2.0.1/dbhome_1)
        (ENVS="TNS_ADMIN=/u01/app/oracle/product/12.2.0.1/dbhome_1")
        )
      )

EOFP
EOF


###test to automate the above

ssh opc@$PRIMARY_PUBLIC_IP_ADDRESS "sudo su - grid" <<EOF 
srvctl stop listener

srvctl start listener

srvctl status listener
EOF

#################################add STANDBY_HOST name to primary db system /etc/hosts file

ssh opc@$PRIMARY_PUBLIC_IP_ADDRESS "sudo su - " <<EOF
echo $STANDBY_HOSTS >>/etc/hosts
EOF


###################add to tnamename.ora file the entery for the standby db system name ###


ssh opc@$PRIMARY_PUBLIC_IP_ADDRESS "sudo su - oracle" <<EOFC
cat >>/u01/app/oracle/product/12.2.0.1/dbhome_1/network/admin/tnsnames.ora <<EOF
ORCL_iad1bz =
  (DESCRIPTION =
    (ADDRESS = (PROTOCOL = TCP)(HOST = ${STANDBY_HOST_NAME}.${STANDBY_DOMAIN_NAME})(PORT = 1521))
    (CONNECT_DATA =
      (SERVER = DEDICATED)
      (SERVICE_NAME = ORCL_iad1bz.${STANDBY_DOMAIN_NAME})
    )
  )

EOF
EOFC


####generate oracle a/c ssh keys for automation to add above

ssh opc@$PRIMARY_PUBLIC_IP_ADDRESS "sudo su - oracle" <<EOF
cd /home/oracle/.ssh
ssh-keygen -N "" -b 2048 -t rsa -f id_rsa -C "oracle_keys"
EOF


ssh opc@$PRIMARY_PUBLIC_IP_ADDRESS "sudo su - oracle" <<EOFC
cat >/home/oracle/dg_steps_primary_1.sql <<EOF
alter system set standby_file_management=AUTO;
alter system set dg_broker_config_file1='+DATA/${PRIMARY_DB_UNIQUE_NAME}/dr1${PRIMARY_DB_UNIQUE_NAME}.dat';
alter system set dg_broker_config_file2='+DATA/${PRIMARY_DB_UNIQUE_NAME}/dr2${PRIMARY_DB_UNIQUE_NAME}.dat';
EOF
EOFC


ssh opc@$PRIMARY_PUBLIC_IP_ADDRESS "sudo su - oracle" <<'EOFC' 
cat >/home/oracle/dg_steps_primary_2.sql <<EOF
select name , value from v\$parameter where name like '%dg_broker%';
alter system set dg_broker_start=true;
select group#, bytes from v\$log;
---check standby log file sizes and they must be same as loigfile sizes
select group#,sum(bytes/1024/1024)"size in MB" from v\$standby_log group by group#;
---check standby log file sizes and they must be same as loigfile sizes
select group#,sum(bytes/1024/1024)"size in MB" from v\$log group by group#;
alter database add standby logfile THREAD 1 group 4 ('+RECO(ONLINELOG)') SIZE 4096M;
alter database add standby logfile THREAD 1 group 5 ('+RECO(ONLINELOG)') SIZE 4096M;
alter database add standby logfile THREAD 1 group 6 ('+RECO(ONLINELOG)') SIZE 4096M;
alter database add standby logfile THREAD 1 group 7 ('+RECO(ONLINELOG)') SIZE 4096M;
--Verify that you created the correct number of SRLs.
select group#, bytes,status from v\$standby_log;
---Make sure the database is in ARCHIVELOG mode.
archive log list
alter database flashback on ;
alter system set db_flashback_retention_target=120;  
alter system switch logfile;
exit;
EOF
EOFC


###run the above sql commands against primary db system


ssh opc@$PRIMARY_PUBLIC_IP_ADDRESS "sudo su - oracle" <<EOFC >/tmp/dg_steps_primary_sql_log.txt
sqlplus / as sysdba << EOF 
@/home/oracle/dg_steps_primary_1.sql
@/home/oracle/dg_steps_primary_2.sql
EOF
EOFC

#
####setup standby server DG 

###setup .profile for bash and other varaibles for standby

ssh -o "StrictHostKeyChecking no" opc@$STANDBY_PUBLIC_IP_ADDRESS "sudo su - oracle" <<'EOF' 
cat >>/home/oracle/.bash_profile <<EOFP
export ORACLE_HOME=/u01/app/oracle/product/12.2.0.1/dbhome_1
export ORACLE_SID=ORCL
export PATH=\$PATH:\$HOME/bin:\$ORACLE_HOME/bin
alias sp='sqlplus / as sysdba'
EOFP
EOF



###tempoarily assume the standby db_unique_name & standby db_domain_name for the standby db###

export STANDBY_DB_UNIQUE_NAME=ORCL_iad1bz

export STANDBY_DB_DOMAIN_NAME=subnet1.ovavcn.oraclevcn.com

####for tde to work correctly we need to set ORACLE_UNQNAME in the bash_profile for standby 
ssh -o "StrictHostKeyChecking no" opc@$STANDBY_PUBLIC_IP_ADDRESS "sudo su - oracle" <<EOF 
cat >>/home/oracle/.bash_profile <<EOFP
export ORACLE_UNQNAME=$STANDBY_DB_UNIQUE_NAME
EOFP
EOF

#################################################################
###add listner.ora entries for grid user



ssh opc@$STANDBY_PUBLIC_IP_ADDRESS "sudo su - grid" <<EOF 
cat >>/u01/app/12.2.0.1/grid/network/admin/listener.ora <<EOFP
SID_LIST_LISTENER=
      (SID_LIST=
        (SID_DESC=
        (SDU=65535)
        (GLOBAL_DBNAME = ${STANDBY_DB_UNIQUE_NAME}.${STANDBY_DB_DOMAIN_NAME})
        (SID_NAME = ORCL)
        (ORACLE_HOME=/u01/app/oracle/product/12.2.0.1/dbhome_1)
        (ENVS="TNS_ADMIN=c")
        )
        (SID_DESC=
        (SDU=65535)
        (GLOBAL_DBNAME = ${STANDBY_DB_UNIQUE_NAME}_DGMGRL.${STANDBY_DB_DOMAIN_NAME})
        (SID_NAME = ORCL)
        (ORACLE_HOME=/u01/app/oracle/product/12.2.0.1/dbhome_1)
        (ENVS="TNS_ADMIN=/u01/app/oracle/product/12.2.0.1/dbhome_1")
        )
      )

EOFP
EOF

### restart the listener after adding above entries

ssh opc@$STANDBY_PUBLIC_IP_ADDRESS "sudo su - grid" <<EOF 
srvctl stop listener
srvctl start listener
srvctl status listener
EOF

###add the primary hostnames to standby hosts file


ssh opc@$STANDBY_PUBLIC_IP_ADDRESS "sudo su - " <<EOF
echo $PRIMARYARY_HOSTS >>/etc/hosts
EOF



####automation to add above

ssh opc@$STANDBY_PUBLIC_IP_ADDRESS "sudo su - oracle" <<EOF
cd /home/oracle/.ssh
ssh-keygen -N "" -b 2048 -t rsa -f id_rsa -C "oracle_keys"
EOF


###############################################################




####automation to add above

ssh opc@$STANDBY_PUBLIC_IP_ADDRESS "sudo su - oracle" <<EOF
mkdir -p /opt/oracle/dcs/commonstore/wallets/tde/${STANDBY_DB_UNIQUE_NAME}
EOF


###############################################################




##get public key from oracle a/c on stby

ssh  opc@$STANDBY_PUBLIC_IP_ADDRESS "sudo su - oracle" <<EOF >/tmp/p1.txt
cat /home/oracle/.ssh/id_rsa.pub
EOF

##keep key in a variable

export ORCL_STANDBY_KEY=`cat /tmp/p1.txt`
echo $ORCL_STANDBY_KEY

##add the key to the primary db system oracle a/c /home/oracle/.ssh/authorized_keys file

ssh opc@$PRIMARY_PUBLIC_IP_ADDRESS "sudo su - oracle" <<EOF
echo $ORCL_STANDBY_KEY >/home/oracle/.ssh/authorized_keys
EOF



###automation to add above



ssh opc@$STANDBY_PUBLIC_IP_ADDRESS "sudo su - oracle" <<EOF
scp -o "StrictHostKeyChecking no" $PRIMARY_PUBLIC_IP_ADDRESS:/opt/oracle/dcs/commonstore/wallets/tde/${PRIMARY_DB_UNIQUE_NAME}/* /opt/oracle/dcs/commonstore/wallets/tde/${STANDBY_DB_UNIQUE_NAME}
EOF


###############################################################





###automation to add above

ssh opc@$STANDBY_PUBLIC_IP_ADDRESS "sudo su - oracle" <<'EOF'
orapwd file=$ORACLE_HOME/dbs/orapwORCL password=WElcome123## entries=5
EOF


###############################################################




###automation to add above

export STANDBY_ORACLE_HOME=/u01/app/oracle/product/12.2.0.1/dbhome_1


ssh opc@$STANDBY_PUBLIC_IP_ADDRESS "sudo su - oracle" <<EOFC
cat >>$STANDBY_ORACLE_HOME/network/admin/tnsnames.ora <<EOF
$PRIMARY_DB_UNIQUE_NAME =
  (DESCRIPTION =
    (ADDRESS = (PROTOCOL = TCP)(HOST = ${PRIMARY_HOST_NAME}.${PRIMARY_DOMAIN_NAME})(PORT = 1521))
    (CONNECT_DATA =
      (SERVER = DEDICATED)
      (SERVICE_NAME = ${PRIMARY_DB_UNIQUE_NAME}.${PRIMARY_DB_DOMAIN_NAME})
    )
  )


${STANDBY_DB_UNIQUE_NAME} =
  (DESCRIPTION =
    (ADDRESS = (PROTOCOL = TCP)(HOST = ${STANDBY_HOST_NAME}.${STANDBY_DOMAIN_NAME})(PORT = 1521))
    (CONNECT_DATA =
      (SERVER = DEDICATED)
      (SERVICE_NAME = ${STANDBY_DB_UNIQUE_NAME}.${STANDBY_DB_DOMAIN_NAME})
    )
  )


##Make sure to add LISTENER_ORCL to the tnsnames.ora file on the standby database


LISTENER_ORCL =
  (ADDRESS = (PROTOCOL = TCP)(HOST = ${STANDBY_HOST_NAME}.${STANDBY_DOMAIN_NAME})(PORT = 1521))


EOF


EOFC


###############################################################



###test to automate above

ssh opc@$STANDBY_PUBLIC_IP_ADDRESS "sudo su - oracle" <<EOFC
mkdir -p /u01/app/oracle/admin/${STANDBY_DB_UNIQUE_NAME}/adump
EOFC




###test to automate above

ssh opc@$STANDBY_PUBLIC_IP_ADDRESS "sudo su - oracle" <<EOFC
cat > /u01/app/oracle/product/12.2.0.1/dbhome_1/dbs/initORCL.ora <<EOF
db_name=ORCL
db_unique_name=${STANDBY_DB_UNIQUE_NAME}
db_domain=${STANDBY_DB_DOMAIN_NAME}
EOF
EOFC


#########################

###test to automate above


ssh opc@$STANDBY_PUBLIC_IP_ADDRESS "sudo su - oracle" <<'EOFC' >/tmp/db_domain.txt
sqlplus -s / as sysdba << EOF 
startup nomount;
EOF
EOFC

#########################################

echo "I am here now --1"


ssh opc@$STANDBY_PUBLIC_IP_ADDRESS "sudo su - oracle" <<EOFC >/tmp/db_domain_rman.txt
rman target sys/WElcome123##@${PRIMARY_DB_UNIQUE_NAME}   auxiliary sys/WElcome123##@${STANDBY_DB_UNIQUE_NAME} log=rman.out <<EOF
run { allocate channel prim1 type disk;
      allocate auxiliary channel sby type disk;
      duplicate target database for standby from active database
      dorecover
      spfile
      parameter_value_convert '/${PRIMARY_DB_UNIQUE_NAME}/','/${STANDBY_DB_UNIQUE_NAME}/','/${PRIMARY_DB_UNIQUE_NAME}/','/${STANDBY_DB_UNIQUE_NAME}/'
      set db_unique_name='${STANDBY_DB_UNIQUE_NAME}'           
      set dg_broker_config_file1='+DATA/${STANDBY_DB_UNIQUE_NAME}/dr1${STANDBY_DB_UNIQUE_NAME}.dat'
      set dg_broker_config_file2='+DATA/${STANDBY_DB_UNIQUE_NAME}/dr2${STANDBY_DB_UNIQUE_NAME}.dat'
      set dispatchers ='(PROTOCOL=TCP) (SERVICE=${STANDBY_DB_UNIQUE_NAME}XDB)'
      set instance_name='${STANDBY_DB_UNIQUE_NAME}'  
            ;
    }

EOF
EOFC

echo "I am here now --2"
###run below sqlplus commands

ssh opc@$STANDBY_PUBLIC_IP_ADDRESS "sudo su - oracle" <<EOFC
cat >/home/oracle/dg_steps_standby_1.sql <<EOF
select status from v\$instance;
alter database open;
alter database flashback on ;
alter system set db_flashback_retention_target=120;  
select FORCE_LOGGING, FLASHBACK_ON, OPEN_MODE, DATABASE_ROLE,SWITCHOVER_STATUS, DATAGUARD_BROKER, PROTECTION_MODE from v\$database ;
----#For ASM storage layout Consider generating the spfile file under +DATA.
create pfile='initORCL.ora' from spfile ;
create spfile='+DATA/\${STANDBY_DB_UNIQUE_NAME}/PARAMETERFILE/spfile' from pfile='initORCL.ora' ;
exit;
EOF
EOFC


###run the sql script on standby


ssh opc@$STANDBY_PUBLIC_IP_ADDRESS "sudo su - oracle" <<EOFC >/tmp/dg_steps_standby_sql_log.txt
sqlplus / as sysdba << EOF 
@/home/oracle/dg_steps_standby_1.sql
EOF
EOFC


##test to automate above

####Stop and remove the existing database service--it does not even exist and so below shall fail

ssh opc@$STANDBY_PUBLIC_IP_ADDRESS "sudo su - oracle" <<EOFC >/tmp/pa_fix_STANDBY_ORACLE_HOME.txt 2>&1
srvctl stop database -d ${STANDBY_DB_UNIQUE_NAME}
srvctl remove database -d ${STANDBY_DB_UNIQUE_NAME}
srvctl add database -d ${STANDBY_DB_UNIQUE_NAME} -n ORCL  -o $STANDBY_ORACLE_HOME -c SINGLE  -p '+DATA/${STANDBY_DB_UNIQUE_NAME}/PARAMETERFILE/spfile' -x ${STANDBY_HOST_NAME}.${STANDBY_DOMAIN_NAME} -s "READ ONLY" -r PHYSICAL_STANDBY -i ORCL
srvctl setenv database -d ${STANDBY_DB_UNIQUE_NAME} -t "ORACLE_UNQNAME=${STANDBY_DB_UNIQUE_NAME}"
srvctl config database -d ${STANDBY_DB_UNIQUE_NAME}
srvctl getenv database -d ${STANDBY_DB_UNIQUE_NAME}
EOFC

#################################


###stop the db using sqlplus / as sysdba



ssh opc@$STANDBY_PUBLIC_IP_ADDRESS "sudo su - oracle" <<'EOFC' >/tmp/db_run_stby.txt
sqlplus -s / as sysdba << EOF 
shutdown immediate;
exit;
EOF
EOFC




###Start the database service using srvctl


ssh opc@$STANDBY_PUBLIC_IP_ADDRESS "sudo su - oracle" <<EOFC
srvctl start database -d ${STANDBY_DB_UNIQUE_NAME}
EOFC



#Clean up the files from $ORACLE_HOME/dbs.

ssh opc@$STANDBY_PUBLIC_IP_ADDRESS "sudo su - oracle" <<EOFC
rm $ORACLE_HOME/dbs/initORCL.ora
rm $ORACLE_HOME/dbs/spfileORCL.ora
###Create $ORACLE_HOME/dbs/initORCL.ora file to reference the new location of the spfile file.
cat >$ORACLE_HOME/dbs/initORCL.ora <<EOF
SPFILE='+DATA/${STANDBY_DB_UNIQUE_NAME}/PARAMETERFILE/spfile'
EOF
EOFC



##Stop/start the database and start the standby database by using srvctl.



ssh opc@$STANDBY_PUBLIC_IP_ADDRESS "sudo su - oracle" <<EOFC
srvctl stop database -d ${STANDBY_DB_UNIQUE_NAME}
srvctl start database -d ${STANDBY_DB_UNIQUE_NAME}
EOFC


###setup DG now

#export PRIMARY_DB_UNIQUE_NAME=ORCL_phx1bc

ssh opc@$STANDBY_PUBLIC_IP_ADDRESS "sudo su - oracle" <<EOFC
dgmgrl sys/WElcome123##@$PRIMARY_DB_UNIQUE_NAME <<EOF
create configuration mystby as primary database is $PRIMARY_DB_UNIQUE_NAME  connect identifier is $PRIMARY_DB_UNIQUE_NAME;
add database  ${STANDBY_DB_UNIQUE_NAME} as connect identifier is ${STANDBY_DB_UNIQUE_NAME}  maintained as physical;
enable configuration;
show configuration verbose;
show database verbose ${STANDBY_DB_UNIQUE_NAME};
show database verbose $PRIMARY_DB_UNIQUE_NAME;
show configuration verbose;
edit database $PRIMARY_DB_UNIQUE_NAME set property ApplyLagThreshold='3600';
edit database $PRIMARY_DB_UNIQUE_NAME set property TransportLagThreshold='3600';
edit database $PRIMARY_DB_UNIQUE_NAME set property TransportDisconnectedThreshold='3600';
edit database ${STANDBY_DB_UNIQUE_NAME} set property ApplyLagThreshold='3600';
edit database ${STANDBY_DB_UNIQUE_NAME} set property TransportLagThreshold='3600';
edit database ${STANDBY_DB_UNIQUE_NAME} set property TransportDisconnectedThreshold='3600';
show configuration verbose;
exit;
EOF
EOFC

ssh opc@$PRIMARY_PUBLIC_IP_ADDRESS "sudo su - oracle" <<\EOFC
cat >/home/oracle/dg_steps_primary_2.sql <<EOF
select FORCE_LOGGING, FLASHBACK_ON, OPEN_MODE, DATABASE_ROLE, SWITCHOVER_STATUS, DATAGUARD_BROKER, PROTECTION_MODE from v\$database;
alter system switch logfile;
alter system switch logfile;
alter system switch logfile;
show parameter log_archive_dest_
show parameter log_archive_config
show parameter fal_server
show parameter log_archive_format
Select fs_failover_status,fs_failover_observer_present from v\$database; 
exit;
EOF
EOFC


###run the sql script on standby


ssh opc@$PRIMARY_PUBLIC_IP_ADDRESS "sudo su - oracle" <<EOFC >/tmp/dg_steps_standby_sql_log.txt
sqlplus / as sysdba << EOF 
@/home/oracle/dg_steps_primary_2.sql
EOF
EOFC



##Verify that Data Guard processes are initiated in the standby database.



ssh opc@$STANDBY_PUBLIC_IP_ADDRESS "sudo su - oracle" <<\EOFC
cat >/home/oracle/dg_steps_standby_2.sql <<EOF
select PROCESS,PID,DELAY_MINS from V\$MANAGED_STANDBY;
show parameter log_archive_dest_
show parameter log_archive_config
show parameter fal_server
show parameter log_archive_format
Select fs_failover_status,fs_failover_observer_present from v\$database; 
exit;
EOF
EOFC


###run the sql script on standby


ssh opc@$STANDBY_PUBLIC_IP_ADDRESS "sudo su - oracle" <<EOFC >/tmp/dg_steps_primary_sql_2_log.txt
sqlplus / as sysdba << EOF 
@/home/oracle/dg_steps_standby_2.sql
EOF
EOFC

ssh opc@$STANDBY_PUBLIC_IP_ADDRESS "sudo su - oracle" <<EOFC
dgmgrl sys/WElcome123##@$PRIMARY_DB_UNIQUE_NAME <<EOF
show configuration verbose;
show database verbose ${STANDBY_DB_UNIQUE_NAME};
show database verbose $PRIMARY_DB_UNIQUE_NAME;
show configuration verbose;
edit database ${STANDBY_DB_UNIQUE_NAME} set property 'logXptMode'='SYNC';
edit database $PRIMARY_DB_UNIQUE_NAME set property 'logXptMode'='SYNC';
edit configuration set protection mode as maxavailability;
show configuration verbose;
edit database $PRIMARY_DB_UNIQUE_NAME set property faststartfailovertarget='${STANDBY_DB_UNIQUE_NAME}';
edit database  ${STANDBY_DB_UNIQUE_NAME} set property faststartfailovertarget='$PRIMARY_DB_UNIQUE_NAME';
edit configuration set property FastStartFailoverLagLimit='3600';
show configuration verbose;
exit;
EOF
EOFC



#########srart the observer integration ####


###create terraform instance for OL7.5 and then install oracle prereqs

cd  oci-arch-bmdb-ha-master/observer-one
OBS_ONE_DOMAIN_NAME=subnet1.ovavcn.oraclevcn.com
echo $OBS_ONE_DOMAIN_NAME
export OBS_ONE_DOMAIN_NAME
OBS_ONE_HOST_NAME=`cat main.tf|grep -i hostname_label| awk -F "=" '{print $2}'|tr -d '"'|tr -d ' '`
echo $OBS_ONE_HOST_NAME
export OBS_ONE_HOST_NAME
OBS_ONE_PUBLIC_IP_ADDRESS=`terraform output "InstancePublicIP-ol7"`
echo $OBS_ONE_PUBLIC_IP_ADDRESS
export OBS_ONE_PUBLIC_IP_ADDRESS
echo $OBS_ONE_PUBLIC_IP_ADDRESS ${OBS_ONE_HOST_NAME}.${OBS_ONE_DOMAIN_NAME}
echo $OBS_ONE_PUBLIC_IP_ADDRESS ${OBS_ONE_HOST_NAME}.${OBS_ONE_DOMAIN_NAME} > my_observer_system_hostname_ip_details.txt
export OBS_ONEARY_HOSTS=$(echo ${OBS_ONE_PUBLIC_IP_ADDRESS} ${OBS_ONE_HOST_NAME}.${OBS_ONE_DOMAIN_NAME})
echo $OBS_ONEARY_HOSTS

ssh -o "StrictHostKeyChecking no" opc@$OBS_ONE_PUBLIC_IP_ADDRESS "sudo su - " <<EOFC 
mkdir /u01
mkdir /u01/12C_DB_INSTALLABLES
chown -R oracle:dba /u01
chmod 777 /u01/12C_DB_INSTALLABLES
EOFC

scp linuxx64_12201_database.zip opc@$OBS_ONE_PUBLIC_IP_ADDRESS:/u01/12C_DB_INSTALLABLES


ssh opc@$OBS_ONE_PUBLIC_IP_ADDRESS "sudo su - oracle" <<'EOFC'
cd /u01/12C_DB_INSTALLABLES 
unzip -qq /u01/12C_DB_INSTALLABLES/linuxx64_12201_database.zip
EOFC


ssh opc@$OBS_ONE_PUBLIC_IP_ADDRESS "sudo su - oracle" <<'EOFC'
cd /u01/12C_DB_INSTALLABLES 
unzip -qq /u01/12C_DB_INSTALLABLES/linuxx64_12201_database.zip
EOFC


ssh opc@$OBS_ONE_PUBLIC_IP_ADDRESS "sudo su - oracle" <<EOFC
cd /u01/12C_DB_INSTALLABLES/database
./runInstaller -waitforcompletion -showProgress -silent \
    -responseFile /u01/12C_DB_INSTALLABLES/database/response/db_install.rsp \
    oracle.install.option=INSTALL_DB_SWONLY \
    ORACLE_HOSTNAME=${OBS_ONE_HOST_NAME}.${OBS_ONE_DOMAIN_NAME} \
    UNIX_GROUP_NAME=oinstall \
    INVENTORY_LOCATION=/u01/app/oraInventory \
    SELECTED_LANGUAGES=en,en_GB \
    ORACLE_HOME=/u01/app/oracle/product/12.2.0.1/dbhome_1 \
    ORACLE_BASE=/u01/app/oracle \
    oracle.install.db.InstallEdition=EE \
    oracle.install.db.OSDBA_GROUP=dba \
    oracle.install.db.OSBACKUPDBA_GROUP=dba \
    oracle.install.db.OSDGDBA_GROUP=dba \
    oracle.install.db.OSKMDBA_GROUP=dba \
    oracle.install.db.OSRACDBA_GROUP=dba \
    SECURITY_UPDATES_VIA_MYORACLESUPPORT=false \
    DECLINE_SECURITY_UPDATES=true 
EOFC

ssh opc@$OBS_ONE_PUBLIC_IP_ADDRESS "sudo su -" <<'EOFC' 
/u01/app/oraInventory/orainstRoot.sh
/u01/app/oracle/product/12.2.0.1/dbhome_1/root.sh
EOFC

ssh opc@$OBS_ONE_PUBLIC_IP_ADDRESS "sudo su - oracle" <<'EOFC'
mkdir /home/oracle/wallet
EOFC


######set up primary by ssh and setup the bash_profile

ssh -o "StrictHostKeyChecking no" opc@$OBS_ONE_PUBLIC_IP_ADDRESS  "sudo su - oracle" <<'EOF'
cat >>/home/oracle/.bash_profile <<EOFP
export ORACLE_HOME=/u01/app/oracle/product/12.2.0.1/dbhome_1
export PATH=\$PATH:\$HOME/bin:\$ORACLE_HOME/bin
export LD_LIBRARY_PATH=$ORACLE_HOME/lib
alias sp='sqlplus / as sysdba'
EOFP
EOF


###add entries for tnsnames.ora to observer for primary and standby

export STANDBY_ORACLE_HOME=/u01/app/oracle/product/12.2.0.1/dbhome_1


ssh opc@$OBS_ONE_PUBLIC_IP_ADDRESS "sudo su - oracle" <<EOFC
cat >>$STANDBY_ORACLE_HOME/network/admin/tnsnames.ora <<EOF
$PRIMARY_DB_UNIQUE_NAME =
  (DESCRIPTION =
    (ADDRESS = (PROTOCOL = TCP)(HOST = ${PRIMARY_HOST_NAME}.${PRIMARY_DOMAIN_NAME})(PORT = 1521))
    (CONNECT_DATA =
      (SERVER = DEDICATED)
      (SERVICE_NAME = ${PRIMARY_DB_UNIQUE_NAME}.${PRIMARY_DB_DOMAIN_NAME})
    )
  )


${STANDBY_DB_UNIQUE_NAME} =
  (DESCRIPTION =
    (ADDRESS = (PROTOCOL = TCP)(HOST = ${STANDBY_HOST_NAME}.${STANDBY_DOMAIN_NAME})(PORT = 1521))
    (CONNECT_DATA =
      (SERVER = DEDICATED)
      (SERVICE_NAME = ${STANDBY_DB_UNIQUE_NAME}.${STANDBY_DB_DOMAIN_NAME})
    )
  )

EOF


EOFC


ssh opc@$OBS_ONE_PUBLIC_IP_ADDRESS "sudo su - oracle" <<EOFC
cat >>$STANDBY_ORACLE_HOME/network/admin/sqlnet.ora <<EOF
WALLET_LOCATION=(SOURCE=(METHOD=FILE)(METHOD_DATA=(DIRECTORY=/home/oracle/wallet)))
SQLNET.WALLET_OVERRIDE = TRUE
EOF
EOFC

###############################################################

###add entries to /etc/hosts for the primary and standby hosts to the observer

ssh opc@$OBS_ONE_PUBLIC_IP_ADDRESS "sudo su - " <<EOF
echo $STANDBY_HOSTS >>/etc/hosts
EOF


ssh opc@$OBS_ONE_PUBLIC_IP_ADDRESS "sudo su - " <<EOF
echo $PRIMARYARY_HOSTS >>/etc/hosts
EOF


#####add the wallet entries to observer
ssh opc@$OBS_ONE_PUBLIC_IP_ADDRESS "sudo su - oracle" <<EOF
echo -e "M@nager@1234\nM@nager@1234"|mkstore -wrl /home/oracle/wallet -create
echo M@nager@1234|mkstore -wrl /home/oracle/wallet -createCredential ${STANDBY_DB_UNIQUE_NAME} SYS WElcome123##
echo M@nager@1234|mkstore -wrl /home/oracle/wallet -createCredential $PRIMARY_DB_UNIQUE_NAME SYS WElcome123##
echo M@nager@1234|mkstore -wrl /home/oracle/wallet -listCredential
EOF


ssh -t opc@$OBS_ONE_PUBLIC_IP_ADDRESS "sudo su - oracle" <<EOFC
cd /home/oracle
dgmgrl sys/WElcome123##@$PRIMARY_DB_UNIQUE_NAME <<EOF >/tmp/null_$OBS_ONE_HOST_NAME 2>&1
show configuration verbose;
enable fast_start failover;
START OBSERVER $OBS_ONE_HOST_NAME IN BACKGROUND FILE IS observer.dat LOGFILE IS observer.log CONNECT IDENTIFIER IS ${STANDBY_DB_UNIQUE_NAME};
show database verbose ${STANDBY_DB_UNIQUE_NAME};
show database verbose $PRIMARY_DB_UNIQUE_NAME;
show configuration verbose;
exit;

EOF
EOFC

###because of the above sshd bug we need to print contents if there were any errors
ssh opc@$OBS_ONE_PUBLIC_IP_ADDRESS "sudo su - oracle" <<EOFC
cat /tmp/null_$OBS_ONE_HOST_NAME
EOFC



#########srart the observer 2 integration ####


###create terraform instance for OL7.5 and then install oracle prereqs

cd  oci-arch-bmdb-ha-master/observer-two
OBS_TWO_DOMAIN_NAME=subnet1.ovavcn.oraclevcn.com
echo $OBS_TWO_DOMAIN_NAME
export OBS_TWO_DOMAIN_NAME
OBS_TWO_HOST_NAME=`cat main.tf|grep -i hostname_label| awk -F "=" '{print $2}'|tr -d '"'|tr -d ' '`
echo $OBS_TWO_HOST_NAME
export OBS_TWO_HOST_NAME
OBS_TWO_PUBLIC_IP_ADDRESS=`terraform output "InstancePublicIP-ol7"`
echo $OBS_TWO_PUBLIC_IP_ADDRESS
export OBS_TWO_PUBLIC_IP_ADDRESS
echo $OBS_TWO_PUBLIC_IP_ADDRESS ${OBS_TWO_HOST_NAME}.${OBS_TWO_DOMAIN_NAME}
echo $OBS_TWO_PUBLIC_IP_ADDRESS ${OBS_TWO_HOST_NAME}.${OBS_TWO_DOMAIN_NAME} > my_observer_system_hostname_ip_details.txt
export OBS_TWOARY_HOSTS=$(echo ${OBS_TWO_PUBLIC_IP_ADDRESS} ${OBS_TWO_HOST_NAME}.${OBS_TWO_DOMAIN_NAME})
echo $OBS_TWOARY_HOSTS

ssh -o "StrictHostKeyChecking no" opc@$OBS_TWO_PUBLIC_IP_ADDRESS "sudo su - " <<EOFC 
mkdir /u01
mkdir /u01/12C_DB_INSTALLABLES
chown -R oracle:dba /u01
chmod 777 /u01/12C_DB_INSTALLABLES
EOFC

scp linuxx64_12201_database.zip opc@$OBS_TWO_PUBLIC_IP_ADDRESS:/u01/12C_DB_INSTALLABLES


ssh opc@$OBS_TWO_PUBLIC_IP_ADDRESS "sudo su - oracle" <<'EOFC'
cd /u01/12C_DB_INSTALLABLES 
unzip -qq /u01/12C_DB_INSTALLABLES/linuxx64_12201_database.zip
EOFC


ssh opc@$OBS_TWO_PUBLIC_IP_ADDRESS "sudo su - oracle" <<'EOFC'
cd /u01/12C_DB_INSTALLABLES 
unzip -qq /u01/12C_DB_INSTALLABLES/linuxx64_12201_database.zip
EOFC


ssh opc@$OBS_TWO_PUBLIC_IP_ADDRESS "sudo su - oracle" <<EOFC
cd /u01/12C_DB_INSTALLABLES/database
./runInstaller -waitforcompletion -showProgress -silent \
    -responseFile /u01/12C_DB_INSTALLABLES/database/response/db_install.rsp \
    oracle.install.option=INSTALL_DB_SWONLY \
    ORACLE_HOSTNAME=${OBS_TWO_HOST_NAME}.${OBS_TWO_DOMAIN_NAME} \
    UNIX_GROUP_NAME=oinstall \
    INVENTORY_LOCATION=/u01/app/oraInventory \
    SELECTED_LANGUAGES=en,en_GB \
    ORACLE_HOME=/u01/app/oracle/product/12.2.0.1/dbhome_1 \
    ORACLE_BASE=/u01/app/oracle \
    oracle.install.db.InstallEdition=EE \
    oracle.install.db.OSDBA_GROUP=dba \
    oracle.install.db.OSBACKUPDBA_GROUP=dba \
    oracle.install.db.OSDGDBA_GROUP=dba \
    oracle.install.db.OSKMDBA_GROUP=dba \
    oracle.install.db.OSRACDBA_GROUP=dba \
    SECURITY_UPDATES_VIA_MYORACLESUPPORT=false \
    DECLINE_SECURITY_UPDATES=true 
EOFC

ssh opc@$OBS_TWO_PUBLIC_IP_ADDRESS "sudo su -" <<'EOFC' 
/u01/app/oraInventory/orainstRoot.sh
/u01/app/oracle/product/12.2.0.1/dbhome_1/root.sh
EOFC

ssh opc@$OBS_TWO_PUBLIC_IP_ADDRESS "sudo su - oracle" <<'EOFC'
mkdir /home/oracle/wallet
EOFC


######set up primary by ssh and setup the bash_profile

ssh -o "StrictHostKeyChecking no" opc@$OBS_TWO_PUBLIC_IP_ADDRESS  "sudo su - oracle" <<'EOF'
cat >>/home/oracle/.bash_profile <<EOFP
export ORACLE_HOME=/u01/app/oracle/product/12.2.0.1/dbhome_1
export PATH=\$PATH:\$HOME/bin:\$ORACLE_HOME/bin
export LD_LIBRARY_PATH=$ORACLE_HOME/lib
alias sp='sqlplus / as sysdba'
EOFP
EOF


###add entries for tnsnames.ora to observer for primary and standby

export STANDBY_ORACLE_HOME=/u01/app/oracle/product/12.2.0.1/dbhome_1


ssh opc@$OBS_TWO_PUBLIC_IP_ADDRESS "sudo su - oracle" <<EOFC
cat >>$STANDBY_ORACLE_HOME/network/admin/tnsnames.ora <<EOF
$PRIMARY_DB_UNIQUE_NAME =
  (DESCRIPTION =
    (ADDRESS = (PROTOCOL = TCP)(HOST = ${PRIMARY_HOST_NAME}.${PRIMARY_DOMAIN_NAME})(PORT = 1521))
    (CONNECT_DATA =
      (SERVER = DEDICATED)
      (SERVICE_NAME = ${PRIMARY_DB_UNIQUE_NAME}.${PRIMARY_DB_DOMAIN_NAME})
    )
  )


${STANDBY_DB_UNIQUE_NAME} =
  (DESCRIPTION =
    (ADDRESS = (PROTOCOL = TCP)(HOST = ${STANDBY_HOST_NAME}.${STANDBY_DOMAIN_NAME})(PORT = 1521))
    (CONNECT_DATA =
      (SERVER = DEDICATED)
      (SERVICE_NAME = ${STANDBY_DB_UNIQUE_NAME}.${STANDBY_DB_DOMAIN_NAME})
    )
  )

EOF


EOFC


ssh opc@$OBS_TWO_PUBLIC_IP_ADDRESS "sudo su - oracle" <<EOFC
cat >>$STANDBY_ORACLE_HOME/network/admin/sqlnet.ora <<EOF
WALLET_LOCATION=(SOURCE=(METHOD=FILE)(METHOD_DATA=(DIRECTORY=/home/oracle/wallet)))
SQLNET.WALLET_OVERRIDE = TRUE
EOF
EOFC

###############################################################

###add entries to /etc/hosts for the primary and standby hosts to the observer

ssh opc@$OBS_TWO_PUBLIC_IP_ADDRESS "sudo su - " <<EOF
echo $STANDBY_HOSTS >>/etc/hosts
EOF


ssh opc@$OBS_TWO_PUBLIC_IP_ADDRESS "sudo su - " <<EOF
echo $PRIMARYARY_HOSTS >>/etc/hosts
EOF


#####add the wallet entries to observer
ssh opc@$OBS_TWO_PUBLIC_IP_ADDRESS "sudo su - oracle" <<EOF
echo -e "M@nager@1234\nM@nager@1234"|mkstore -wrl /home/oracle/wallet -create
echo M@nager@1234|mkstore -wrl /home/oracle/wallet -createCredential ${STANDBY_DB_UNIQUE_NAME} SYS WElcome123##
echo M@nager@1234|mkstore -wrl /home/oracle/wallet -createCredential $PRIMARY_DB_UNIQUE_NAME SYS WElcome123##
echo M@nager@1234|mkstore -wrl /home/oracle/wallet -listCredential
EOF


ssh -t opc@$OBS_TWO_PUBLIC_IP_ADDRESS "sudo su - oracle" <<EOFC
cd /home/oracle
dgmgrl sys/WElcome123##@$PRIMARY_DB_UNIQUE_NAME <<EOF >/tmp/null_$OBS_TWO_HOST_NAME 2>&1 
show configuration verbose;
enable fast_start failover;
START OBSERVER $OBS_TWO_HOST_NAME IN BACKGROUND FILE IS observer.dat LOGFILE IS observer.log CONNECT IDENTIFIER IS ${STANDBY_DB_UNIQUE_NAME};
show database verbose ${STANDBY_DB_UNIQUE_NAME};
show database verbose $PRIMARY_DB_UNIQUE_NAME;
show configuration verbose;
exit;

EOF
EOFC

###because of the above sshd bug we need to print contents if there were any errors
ssh opc@$OBS_TWO_PUBLIC_IP_ADDRESS "sudo su - oracle" <<EOFC
cat /tmp/null_$OBS_TWO_HOST_NAME
EOFC
#########srart the observer 3 integration ####



###create terraform instance for OL7.5 and then install oracle prereqs

cd  oci-arch-bmdb-ha-master/observer-three
OBS_THREE_DOMAIN_NAME=subnet1.ovavcn.oraclevcn.com
echo $OBS_THREE_DOMAIN_NAME
export OBS_THREE_DOMAIN_NAME
OBS_THREE_HOST_NAME=`cat main.tf|grep -i hostname_label| awk -F "=" '{print $2}'|tr -d '"'|tr -d ' '`
echo $OBS_THREE_HOST_NAME
export OBS_THREE_HOST_NAME
OBS_THREE_PUBLIC_IP_ADDRESS=`terraform output "InstancePublicIP-ol7"`
echo $OBS_THREE_PUBLIC_IP_ADDRESS
export OBS_THREE_PUBLIC_IP_ADDRESS
echo $OBS_THREE_PUBLIC_IP_ADDRESS ${OBS_THREE_HOST_NAME}.${OBS_THREE_DOMAIN_NAME}
echo $OBS_THREE_PUBLIC_IP_ADDRESS ${OBS_THREE_HOST_NAME}.${OBS_THREE_DOMAIN_NAME} > my_observer_system_hostname_ip_details.txt
export OBS_THREEARY_HOSTS=$(echo ${OBS_THREE_PUBLIC_IP_ADDRESS} ${OBS_THREE_HOST_NAME}.${OBS_THREE_DOMAIN_NAME})
echo $OBS_THREEARY_HOSTS

ssh -o "StrictHostKeyChecking no" opc@$OBS_THREE_PUBLIC_IP_ADDRESS "sudo su - " <<EOFC 
mkdir /u01
mkdir /u01/12C_DB_INSTALLABLES
chown -R oracle:dba /u01
chmod 777 /u01/12C_DB_INSTALLABLES
EOFC

scp linuxx64_12201_database.zip opc@$OBS_THREE_PUBLIC_IP_ADDRESS:/u01/12C_DB_INSTALLABLES


ssh opc@$OBS_THREE_PUBLIC_IP_ADDRESS "sudo su - oracle" <<'EOFC'
cd /u01/12C_DB_INSTALLABLES 
unzip -qq /u01/12C_DB_INSTALLABLES/linuxx64_12201_database.zip
EOFC


ssh opc@$OBS_THREE_PUBLIC_IP_ADDRESS "sudo su - oracle" <<'EOFC'
cd /u01/12C_DB_INSTALLABLES 
unzip -qq /u01/12C_DB_INSTALLABLES/linuxx64_12201_database.zip
EOFC


ssh opc@$OBS_THREE_PUBLIC_IP_ADDRESS "sudo su - oracle" <<EOFC
cd /u01/12C_DB_INSTALLABLES/database
./runInstaller -waitforcompletion -showProgress -silent \
    -responseFile /u01/12C_DB_INSTALLABLES/database/response/db_install.rsp \
    oracle.install.option=INSTALL_DB_SWONLY \
    ORACLE_HOSTNAME=${OBS_THREE_HOST_NAME}.${OBS_THREE_DOMAIN_NAME} \
    UNIX_GROUP_NAME=oinstall \
    INVENTORY_LOCATION=/u01/app/oraInventory \
    SELECTED_LANGUAGES=en,en_GB \
    ORACLE_HOME=/u01/app/oracle/product/12.2.0.1/dbhome_1 \
    ORACLE_BASE=/u01/app/oracle \
    oracle.install.db.InstallEdition=EE \
    oracle.install.db.OSDBA_GROUP=dba \
    oracle.install.db.OSBACKUPDBA_GROUP=dba \
    oracle.install.db.OSDGDBA_GROUP=dba \
    oracle.install.db.OSKMDBA_GROUP=dba \
    oracle.install.db.OSRACDBA_GROUP=dba \
    SECURITY_UPDATES_VIA_MYORACLESUPPORT=false \
    DECLINE_SECURITY_UPDATES=true 
EOFC

ssh opc@$OBS_THREE_PUBLIC_IP_ADDRESS "sudo su -" <<'EOFC' 
/u01/app/oraInventory/orainstRoot.sh
/u01/app/oracle/product/12.2.0.1/dbhome_1/root.sh
EOFC

ssh opc@$OBS_THREE_PUBLIC_IP_ADDRESS "sudo su - oracle" <<'EOFC'
mkdir /home/oracle/wallet
EOFC


######set up primary by ssh and setup the bash_profile

ssh -o "StrictHostKeyChecking no" opc@$OBS_THREE_PUBLIC_IP_ADDRESS  "sudo su - oracle" <<'EOF'
cat >>/home/oracle/.bash_profile <<EOFP
export ORACLE_HOME=/u01/app/oracle/product/12.2.0.1/dbhome_1
export PATH=\$PATH:\$HOME/bin:\$ORACLE_HOME/bin
export LD_LIBRARY_PATH=$ORACLE_HOME/lib
alias sp='sqlplus / as sysdba'
EOFP
EOF


###add entries for tnsnames.ora to observer for primary and standby

export STANDBY_ORACLE_HOME=/u01/app/oracle/product/12.2.0.1/dbhome_1


ssh opc@$OBS_THREE_PUBLIC_IP_ADDRESS "sudo su - oracle" <<EOFC
cat >>$STANDBY_ORACLE_HOME/network/admin/tnsnames.ora <<EOF
$PRIMARY_DB_UNIQUE_NAME =
  (DESCRIPTION =
    (ADDRESS = (PROTOCOL = TCP)(HOST = ${PRIMARY_HOST_NAME}.${PRIMARY_DOMAIN_NAME})(PORT = 1521))
    (CONNECT_DATA =
      (SERVER = DEDICATED)
      (SERVICE_NAME = ${PRIMARY_DB_UNIQUE_NAME}.${PRIMARY_DB_DOMAIN_NAME})
    )
  )


${STANDBY_DB_UNIQUE_NAME} =
  (DESCRIPTION =
    (ADDRESS = (PROTOCOL = TCP)(HOST = ${STANDBY_HOST_NAME}.${STANDBY_DOMAIN_NAME})(PORT = 1521))
    (CONNECT_DATA =
      (SERVER = DEDICATED)
      (SERVICE_NAME = ${STANDBY_DB_UNIQUE_NAME}.${STANDBY_DB_DOMAIN_NAME})
    )
  )

EOF


EOFC


ssh opc@$OBS_THREE_PUBLIC_IP_ADDRESS "sudo su - oracle" <<EOFC
cat >>$STANDBY_ORACLE_HOME/network/admin/sqlnet.ora <<EOF
WALLET_LOCATION=(SOURCE=(METHOD=FILE)(METHOD_DATA=(DIRECTORY=/home/oracle/wallet)))
SQLNET.WALLET_OVERRIDE = TRUE
EOF
EOFC

###############################################################

###add entries to /etc/hosts for the primary and standby hosts to the observer

ssh opc@$OBS_THREE_PUBLIC_IP_ADDRESS "sudo su - " <<EOF
echo $STANDBY_HOSTS >>/etc/hosts
EOF


ssh opc@$OBS_THREE_PUBLIC_IP_ADDRESS "sudo su - " <<EOF
echo $PRIMARYARY_HOSTS >>/etc/hosts
EOF


#####add the wallet entries to observer
ssh opc@$OBS_THREE_PUBLIC_IP_ADDRESS "sudo su - oracle" <<EOF
echo -e "M@nager@1234\nM@nager@1234"|mkstore -wrl /home/oracle/wallet -create
echo M@nager@1234|mkstore -wrl /home/oracle/wallet -createCredential ${STANDBY_DB_UNIQUE_NAME} SYS WElcome123##
echo M@nager@1234|mkstore -wrl /home/oracle/wallet -createCredential $PRIMARY_DB_UNIQUE_NAME SYS WElcome123##
echo M@nager@1234|mkstore -wrl /home/oracle/wallet -listCredential
EOF


ssh opc@$OBS_THREE_PUBLIC_IP_ADDRESS "sudo su - oracle" <<EOFC
cd /home/oracle
dgmgrl sys/WElcome123##@$PRIMARY_DB_UNIQUE_NAME <<EOF >/tmp/null_$OBS_THREE_HOST_NAME 2>&1
show configuration verbose;
enable fast_start failover;
START OBSERVER $OBS_THREE_HOST_NAME IN BACKGROUND FILE IS observer.dat LOGFILE IS observer.log CONNECT IDENTIFIER IS ${STANDBY_DB_UNIQUE_NAME};
show database verbose ${STANDBY_DB_UNIQUE_NAME};
show database verbose $PRIMARY_DB_UNIQUE_NAME;
show configuration verbose;
exit;

EOF
EOFC

###because of the above sshd bug we need to print contents if there were any errors
ssh opc@$OBS_THREE_PUBLIC_IP_ADDRESS "sudo su - oracle" <<EOFC
cat /tmp/null_$OBS_THREE_HOST_NAME
EOFC
####at this point we shall delete the TEST instance that we have running on the standby database machine to save resources

ssh opc@$STANDBY_PUBLIC_IP_ADDRESS "sudo su - " <<EOF
/opt/oracle/dcs/bin/dbcli delete-database --dbName TEST
EOF

##maintain security Remove  the standby key from the primary db system oracle a/c /home/oracle/.ssh/authorized_keys file

ssh opc@$PRIMARY_PUBLIC_IP_ADDRESS "sudo su - oracle" <<EOF
cp /dev/null /home/oracle/.ssh/authorized_keys
EOF
###I am resetting all the dataguard timeouts opened to get the automation done to defaults here###
ssh opc@$STANDBY_PUBLIC_IP_ADDRESS "sudo su - oracle" <<EOFC
dgmgrl sys/WElcome123##@$PRIMARY_DB_UNIQUE_NAME <<EOF
show configuration verbose;
show database verbose ${STANDBY_DB_UNIQUE_NAME};
show database verbose $PRIMARY_DB_UNIQUE_NAME;
show configuration verbose;
edit database $PRIMARY_DB_UNIQUE_NAME set property ApplyLagThreshold='30';
edit database $PRIMARY_DB_UNIQUE_NAME set property TransportLagThreshold='30';
edit database $PRIMARY_DB_UNIQUE_NAME set property TransportDisconnectedThreshold='30';
edit database ${STANDBY_DB_UNIQUE_NAME} set property ApplyLagThreshold='30';
edit database ${STANDBY_DB_UNIQUE_NAME} set property TransportLagThreshold='30';
edit database ${STANDBY_DB_UNIQUE_NAME} set property TransportDisconnectedThreshold='30';
edit configuration set property FastStartFailoverLagLimit='30';
show configuration verbose;
show configuration verbose;
show database verbose ${STANDBY_DB_UNIQUE_NAME};
show database verbose $PRIMARY_DB_UNIQUE_NAME;
show configuration verbose;
exit;
EOF
EOFC


#######################print all the commands to access primary/standby & observers
echo "To access primary_db_system use ----ssh opc@$PRIMARY_PUBLIC_IP_ADDRESS" 
echo "To access standby_db_system use ----ssh opc@$STANDBY_PUBLIC_IP_ADDRESS" 
echo "To use DGMGRL in Primary use dgmgrl sys/WElcome123##@$PRIMARY_DB_UNIQUE_NAME" 
echo "To use DGMGRL in  Standby use dgmgrl sys/WElcome123##@$STANDBY_DB_UNIQUE_NAME" 
