#!/bin/bash
# purpose : Perform a backup of APEX application through command line.
# author  :	ajitabhpandey@ajitabhpandey.info
# history : 
#  0.1 on 2018-07-24
#==============================================================================
#
declare -r TMP_FILE_PREFIX=${TMPDIR:-/tmp}/prog.$$
declare -r TIMESTAMP=$(date +%Y%m%d%H)
declare -r MYNAME="$(basename $0)"
declare -r BKPLOCATION="/u01/apex_app_backup"
declare APPID=""

# prints the usage of the script
function usage() {
    echo "Usage: " 
    echo "$MYNAME [-a] [-h]"
    exit 1
}

# checks the required programs - all programs need to be given as parameters
# e.g. - _check_required_programs expdp find logger
function _check_required_programs() {
  for required_prog in ${@}; do
    hash "${required_prog}" 2>&- || \
      {
        logger -p user.error -s "Required program \"${required_prog}\" not installed or not in search PATH"
        exit 1
      }
  done
}

function cleanup() {
  rm -f ${TMP_FILE_PREFIX}.*
  echo "Cleaned up temporary file" && exit 100
}

function create_backup_location() {
    [[ -d $BKPLOCATION ]] | mkdir $BKPLOCATION
}

function main() {
  local -r OPTS=':a:h'

  while builtin getopts ${OPTS} opt; do
    case ${opt} in
      a  ) APPID=$OPTARG
           ;;
      h  ) usage
           ;;
      \? ) logger -p user.error -s "Invalid Option: -$OPTARG"
           usage
           ;;
      :  ) logger -p user.error -s "Invalid Option: -$OPTARG required an argument"
           usage
           ;;
      *  ) logger -p user.error -s "Too many options. You should not see this."
           ;;
    esac
  done
  shift $((OPTIND -1))

  # Check if required programs are installed
  _check_required_programs logger sqlcl

  # Backup the APEX application
  $(sqlcl -s /nolog <<__EOF__
  connect / as sysdba
  set heading off;
  set spool $BKPLOCATION/$APPID.sql;
  apex export $APPID;
  spool off;
  exit;
__EOF__
)