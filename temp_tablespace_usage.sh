#!/bin/bash
#script          : temp_tablespace_usage.sh
#description     : Current usage of temporary tablespace(sort usage) by active users.
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
select S.sid || ',' || S.serial# sid_serial, S.username, S.osuser, P.spid, S.module, S.program, SUM (T.blocks) * TBS.block_size /1024/1024 mb_used, T.tablespace, COUNT(*) sort_ops
from gv\$sort_usage T, gv\$session S, dba_tablespaces TBS, gv\$process P
where T.session_addr = S.saddr AND S.paddr = P.addr AND T.tablespace = TBS.tablespace_name
group by S.sid, S.serial#, S.username, S.osuser, P.spid, S.module, S.program, TBS.block_size, T.tablespace
order by sid_serial;
exit;
EOF
