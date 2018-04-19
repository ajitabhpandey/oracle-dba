#!/bin/bash
# purpose: Displays the space usage of each tablespace in the database.
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
__EOF__

  cleanup

  exit 0
}

# set a trap for cleanup all before process termination by SIGHUBs
trap "cleanup; exit 1" 1 2 3 13 15

# call the main executable function
main "$@"