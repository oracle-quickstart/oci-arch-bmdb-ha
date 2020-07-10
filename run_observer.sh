#!/bin/bash
export ORACLE_HOME=/u01/app/oracle/product/12.2.0.1/dbhome_1
nohup /u01/app/oracle/product/12.2.0.1/dbhome_1/bin/dgmgrl sys/DBAdminPassword@primarydb_db_unique_name "start observer file='/home/oracle/observer.dat'" -logfile /home/oracle/observer.log & 
              