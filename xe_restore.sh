#!/bin/bash
# purpose : Perform restore of Oracle Database using impdp. 
# Backup must have been taken using associated backup script - xe_backup.sh
# 
# author  :	ajitabhpandey@ajitabhpandey.info
# history : 
#  0.1 on 2018-08-13
#==============================================================================
#
declare -r TMP_FILE_PREFIX=${TMPDIR:-/tmp}/prog.$$
declare -r MYNAME="$(basename $0)"
declare -r DPDUMP_PATH="/u01/app/oracle/admin/XE/dpdump/"
declare SCHEMA="FULL"

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

  # set the oracle environment
  ora_env

  # Check if required programs are installed
  _check_required_programs logger impdp find sort head sed

  # Restore the latest full dump first
  declare -r FULL_BKPFILE=$(find ${DPDUMP_PATH} -name *_FULL_*.DMP -type f| sort -r -t_ -k 4|head -1|sed 's#.*/##')
  echo ${FULL_BKPFILE}

  logger -p user.info -s "Restoring full backup using ${FULL_BKPFILE}"
  impdp system DIRECTORY=DATA_PUMP_DIR DUMPFILE=${FULL_BKPFILE} LOGFILE=${FULL_BKPFILE}.log TABLE_EXISTS_ACTION=REPLACE

  if [[ "$SCHEMA" != "FULL" ]]; then
    # Find latest schema backup available for the desired schema
    declare -r SCHEMA_BKPFILE=$(find ${DPDUMP_PATH} -name *_${SCHEMA}_*.DMP -type f| sort -r -t_ -k 4|head -1|sed 's#.*/##')
    echo ${SCHEMA_BKPFILE}

    # Validate if this latest schema backfile file was created after full backup
    declare -r TS_FULL_BKPFILE=$(echo ${FULL_BKPFILE} | cut -d_ -f 4 | sed 's/.DMP$//')
    declare -r TS_SCHEMA_BKPFILE=$(echo ${SCHEMA_BKPFILE} | cut -d_ -f 4 | sed 's/.DMP$//')

    echo ${TS_FULL_BKPFILE}
    echo ${TS_SCHEMA_BKPFILE}

    if [[ ${TS_SCHEMA_BKPFILE} -ge ${TS_FULL_BKPFILE} ]]; then
      # Restore schema backup
      echo "Restoring Schema Backup using ${SCHEMA_BKPFILE} as schema backup is latest"
      logger -p user.info -s "Restoring backup for ${SCHEMA} using ${SCHEMA_BKPFILE}"
      impdp system DIRECTORY=DATA_PUMP_DIR DUMPFILE=${SCHEMA_BKPFILE} LOGFILE=${SCHEMA_BKPFILE}.log TABLE_EXISTS_ACTION=REPLACE
    else
      echo "Full backup is the latest, not restoring the schema backup"
      logger -p user.info -s "Full backup is the latest, not restoring the schema backup"
    fi
  fi

  # Cleanup the temporary file
  cleanup

  exit 0
}

# set a trap for cleanup all before process termination by SIGHUBs
trap "cleanup; exit 1" 1 2 3 13 15

# call the main executable function
main "$@"