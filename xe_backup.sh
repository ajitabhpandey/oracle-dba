#!/bin/sh
# purpose : Perform backup of Oracle Database using expdp.
# author  :	ajitabhpandey@ajitabhpandey.info
# history : 
#  0.1 on 2017-06-04
#  0.2 on 2018-04-18
#==============================================================================
#
declare -r TMP_FILE_PREFIX=${TMPDIR:-/tmp}/prog.$$
declare -r TIMESTAMP=$(date +%Y%m%d%H)
declare -r MYNAME="$(basename $0)"
declare -r SCHEMA="FULL"

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
  if [ -x "$ORA_ENV" ]; then
    . ${ORA_ENV}
  else
    echo "Could not find Oracle Environment"
    logger -p user.error -s "$MYNAME - Could not set Oracle Environment"
    exit 1
  fi
}

function main() {
  local -r OPTS=':s:h'

  while builtin getopts ${OPTS} opt; do
    case ${opt} in
      s  ) SCHEMA=$OPTARG
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

  declare -r BKPFILE="$(hostname)_XE_${SCHEMA}_${TIMESTAMP}"

  if [ "$SCHEMA" == "FULL" ]; then
    # Take a full backup or oracle database
    expdp \"/ as sysdba\" FULL=Y DIRECTORY=DATA_PUMP_DIR DUMPFILE=${BKPFILE}.DMP LOGFILE=${BKPFILE}.log
  else
    # Take backup of specified schema
    expdp \"/ as sysdba\" SCHEMAS=${SCHEMA} DIRECTORY=DATA_PUMP_DIR DUMPFILE=${BKPFILE}.DMP LOGFILE=${BKPFILE}.log
  fi

  # Find backup location and store it in a variable
  BKPLOCATION=$(sqlplus -s /nolog <<__EOF__
  connect / as sysdba
  set heading off;
  select directory_path "Backup Location" from all_directories
  where directory_name='DATA_PUMP_DIR';
  exit;
__EOF__
  )

  if [ ! -z "$BKPLOCATION" ]; then
    # Deleting files older than 1 day
    find $BKPLOCATION \( -name "*.DMP" -o -name "*.log" \) -mtime +1 -print -exec rm -f {} \;|logger -p user.info -t dpdump-cleanup
  else
    logger -p user.error -t dpdump-cleanup -s "Cleanup failed - BKPLOCATION variable is not set"

  cleanup

  exit 0
}

# set a trap for cleanup all before process termination by SIGHUBs
trap "cleanup; exit 1" 1 2 3 13 15

# call the main executable function
main "$@"