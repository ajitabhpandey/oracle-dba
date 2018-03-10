#!/bin/bash
#script          : daily_archive_log.sh
#description     : Archivelog generation of an oracle database on a daily basis.
#author		       : ajitabhpandey@ajitabhpandey.info
#date            : 2017-06-04
#version         : 0.1
#==============================================================================
# Sets the ORACLE ENV Variables
ORA_ENV="/etc/profile.d/oracle_env.sh"
if [ -x "$ORA_ENV" ]
then
 . ${ORA_ENV}

else
 echo "Oracle environment may not be set, further commands may fail."
 echo "You have been warned."

fi

sqlplus -s /nolog << EOF
connect / as sysdba
set pages 1000
set feedback off
set verify off
set echo off
select trunc(COMPLETION_TIME,'DD') Day, thread#, round(sum(BLOCKS*BLOCK_SIZE)/1048576) MB,count(*) Archives_Generated
from v\$archived_log
group by trunc(COMPLETION_TIME,'DD'),thread# order by 1;
exit;
EOF
