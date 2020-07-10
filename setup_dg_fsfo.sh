#!/bin/bash
export ORACLE_HOME=/u01/app/oracle/product/12.2.0.1/dbhome_1
export PATH=$PATH:$ORACLE_HOME/bin
dgmgrl sys/DBAdminPassword@primarydb_db_unique_name "DISABLE fast_start failover;" -logfile /home/oracle/dg_fsfo1.log 
dgmgrl sys/DBAdminPassword@primarydb_db_unique_name "EDIT DATABASE 'primarydb_db_unique_name' SET PROPERTY 'LogXptMode'='SYNC';" -logfile /home/oracle/dg_fsfo2.log             
dgmgrl sys/DBAdminPassword@primarydb_db_unique_name "EDIT DATABASE 'standbydb_db_unique_name' SET PROPERTY 'LogXptMode'='SYNC';" -logfile /home/oracle/dg_fsfo3.log 
dgmgrl sys/DBAdminPassword@primarydb_db_unique_name "EDIT CONFIGURATION SET PROTECTION MODE AS MAXAVAILABILITY;" -logfile /home/oracle/dg_fsfo4.log   
dgmgrl sys/DBAdminPassword@primarydb_db_unique_name "ENABLE fast_start failover;" -logfile /home/oracle/dg_fsfo5.log 

