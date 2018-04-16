#!/bin/sh
#script          : expdp_full.sh
#description     : Perform full backup of Oracle Database using expdp.
#author		 : ajitabhpandey@ajitabhpandey.info
#date            : 2017-06-04
#version         : 0.1    
#==============================================================================
#
TIMESTAMP=$(date +%Y%m%d%H)
MYNAME="$(basename $0)"
SCHEMA="FULL"

# prints the usage of the script
usage() {
    echo "Usage: " 
    echo "$MYNAME [-s] [-h]"
    exit 1
}

# Sets the ORACLE ENV Variables
ora_env() {
  ORA_ENV="/u01/app/oracle/product/11.2.0/xe/bin/oracle_env.sh"
  if [ -x "$ORA_ENV" ]
  then
    . ${ORA_ENV}
  else
    echo "Could not find Oracle Environment"
    logger -s "$MYNAME - Could not set Oracle Environment"
    exit 1
  fi
}

while getopts :s:h opt
do
  case ${opt} in
    s  ) SCHEMA=$OPTARG;;
    h  ) usage;;
    \? ) logger -s "Invalid Option: -$OPTARG"
         usage;;
    :  ) logger -s "Invalid Option: -$OPTARG required an argument"
         usage;;
  esac
done
shift $((OPTIND -1))

BKPFILE="$(hostname)_XE_${SCHEMA}_${TIMESTAMP}"

if [ "$SCHEMA" == "FULL" ]
then
  # Take a full backup or oracle database
  expdp \"/ as sysdba\" FULL=Y DIRECTORY=DATA_PUMP_DIR DUMPFILE=${BKPFILE}.DMP LOGFILE=${BKPFILE}.log
else
  # Take backup of specified schema
  expdp \"/ as sysdba\" SCHEMAS=${SCHEMA} DIRECTORY=DATA_PUMP_DIR DUMPFILE=${BKPFILE}.DMP LOGFILE=${BKPFILE}.log
fi

# Find backup location and store it in a variable
BKPLOCATION=$(sqlplus -s /nolog <<EOF
connect / as sysdba
set heading off;
select directory_path "Backup Location" from all_directories
where directory_name='DATA_PUMP_DIR';
exit;
EOF
)

if [ ! -z "$BKPLOCATION" ]
then
  find $BKPLOCATION \( -name "*.DMP" -o -name "*.log" \) -mtime +1 -exec ls -l {} \;
  # Deleting files older than 1 day
  #find $BKPLOCATION -name *.DMP -name *.log -mtime +1 -exec rm -f {} \;
else
  echo "BKPLOCATION variable is not set"
fi

