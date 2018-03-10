#!/bin/bash
#script          : tablespace_free.sh
#description     : Displays the space usage of each tablespace in the database.
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
set heading on
set pagesize 500
set lines 400

column tablespace       format a30                heading "Tablespace"
column avail            format 9,999,999,999,999  heading "MB Avail."
column used             format 9,999,999,999,999  heading "MB Used"
column free             format 9,999,999,999,999  heading "MB Free"
column pct              format 999                heading "Pct"

compute sum of avail used free on report
break on report
select  a.tablespace_name "Tablespace",
        a.avail,
        a.avail-b.free used,
        b.free,
        round(nvl((a.avail-b.free)/a.avail*100,0))      "Pct"
from
(select tablespace_name, round(sum(bytes)/1048576)     avail
        from    sys.dba_data_files
        group by tablespace_name
        UNION
        select tablespace_name,round(sum(bytes_free+bytes_used)/1048576)
        from v\$temp_space_header
        group by tablespace_name)       a,
(select tablespace_name, round(sum(bytes)/1048576)     free
        from    sys.dba_free_space
        group by tablespace_name
        UNION
        select tablespace_name,round(sum(bytes_free)/1048576)
        from v\$temp_space_header
        group by tablespace_name)       b
where  a.tablespace_name = b.tablespace_name (+);

exit;
EOF
