#!/bin/bash
# purpose: Current usage of temporary tablespace(sort usage) by active users.
# author: ajitabhpandey@ajitabhpandey.info
# history: 
#   0.1 on 2017-06-04
#   0.2 on 2018-04-19
#==============================================================================
declare -r TMP_FILE_PREFIX=${TMPDIR:-/tmp}/prog.$$

# prints the usage of the script
function usage() {
    echo "Usage: " 
    echo "$MYNAME [-s] [-h]"
    exit 1
}

# checks the required programs - all programs need to be given as parameters
# e.g. - _check_required_programs expdp find logger
function _check_required_programs() {
  for required_prog in ${@}; do
    hash "${required_prog}" 2>&- || \ 
      { echo >&2 " Required program \"${required_prog}\" not installed or in search PATH.";
        exit 1;
      }
  done
}

function cleanup() {
  rm -f ${TMP_FILE_PREFIX}.*
  echo "Cleaned up temporary file" && exit 100
}

# Sets the ORACLE ENV Variables
function ora_env() {
  ORA_ENV="/u01/app/oracle/product/11.2.0/xe/bin/oracle_env.sh"
  if [[ -x "$ORA_ENV" ]]; then
    . ${ORA_ENV}
  else
    echo "Could not find Oracle Environment"
    logger -p user.error -s "$MYNAME - Could not set Oracle Environment"
    exit 1
  fi
}

function main() {
  # set the oracle environment
  ora_env

  sqlplus -s /nolog << __EOF__
  connect / as sysdba
  set heading on
  set pagesize 500
  set lines 400
  column    sid_serial  format a10
  column    username    format a20
  column    osuser      format a10
  column    spid        format a6
  column    module      format a15
  column    program     format a15
  column    tablespace  format a10
  select S.sid || ',' || S.serial# sid_serial, S.username, S.osuser, P.spid, S.module, S.program, SUM (T.blocks) * TBS.block_size /1024/1024 mb_used, T.tablespace, COUNT(*) sort_ops
  from gv\$sort_usage T, gv\$session S, dba_tablespaces TBS, gv\$process P
  where T.session_addr = S.saddr AND S.paddr = P.addr AND T.tablespace = TBS.tablespace_name
  group by S.sid, S.serial#, S.username, S.osuser, P.spid, S.module, S.program, TBS.block_size, T.tablespace
  order by sid_serial;
  exit;
__EOF__

  cleanup

  exit 0
}

# set a trap for cleanup all before process termination by SIGHUBs
trap "cleanup; exit 1" 1 2 3 13 15

# call the main executable function
main "$@"