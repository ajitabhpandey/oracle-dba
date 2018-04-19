#!/bin/bash
# purpose: Display the FRA usage
# author:  ajitabhpandey@ajitabhpandey.info
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
  -- Utilisation (MB) du FRA
  set lines 100
  col name format a60

  SELECT
	  name,
	  floor(space_limit / 1024 / 1024) "Size MB",
	  ceil(space_used / 1024 / 1024) "Used MB"
  FROM V\$RECOVERY_FILE_DEST;

  -- FRA Occupants
  SELECT * FROM V\$FLASH_RECOVERY_AREA_USAGE;

  -- Location and size of the FRA
  SHOW PARAMETER DB_RECOVERY_FILE_DEST;

  -- Size, used, Reclaimable
  SELECT
    ROUND((A.SPACE_LIMIT / 1024 / 1024 / 1024), 2) AS FLASH_IN_GB,
    ROUND((A.SPACE_USED / 1024 / 1024 / 1024), 2) AS FLASH_USED_IN_GB,
    ROUND((A.SPACE_RECLAIMABLE / 1024 / 1024 / 1024), 2) AS
  FLASH_RECLAIMABLE_GB,
    SUM(B.PERCENT_SPACE_USED)  AS PERCENT_OF_SPACE_USED
  FROM
    V\$RECOVERY_FILE_DEST A,
    V\$FLASH_RECOVERY_AREA_USAGE B
  GROUP BY
    SPACE_LIMIT,
    SPACE_USED ,
    SPACE_RECLAIMABLE ;

  -- After that you can resize the FRA with:
  -- ALTER SYSTEM SET db_recovery_file_dest_size=xxG;

  -- Or change the FRA to a new location
  -- (new archives will be created to this new location
  -- ALTER SYSTEM SET DB_RECOVERY_FILE_DEST='/u....';

  exit;
__EOF__

  cleanup

  exit 0
}

# set a trap for cleanup all before process termination by SIGHUBs
trap "cleanup; exit 1" 1 2 3 13 15

# call the main executable function
main "$@"