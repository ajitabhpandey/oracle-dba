#!/bin/sh
#script          : expdp_full.sh
#description     : Perform full backup of Oracle Database using expdp.
#author		 : ajitabhpandey@ajitabhpandey.info
#date            : 2017-06-04
#version         : 0.1    
#==============================================================================
#
# Sets the ORACLE ENV Variables
ORA_ENV="/etc/profile.d/oracle_env.sh"
if [ -x "$ORA_ENV" ]
then
 . ${ORA_ENV}

else
 echo "Oracle environment may not be set, further commands may fail."
 echo "You have been warned."

fi

TIMESTAMP=$(date +%Y%m%d%H)
BKPFILE="$(hostname)_XE_FULL_${TIMESTAMP}"

# Take  a full backup of oracle database
expdp \"/ as sysdba\" FULL=Y DIRECTORY=DATA_PUMP_DIR DUMPFILE=${BKPFILE}.DMP LOGFILE=${BKPFILE}.log

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
  find $BKPLOCATION -name *.DMP -name *.log -mtime +1 -exec ls -l {} \;
  # Deleting files older than 1 day
  #find $BKPLOCATION -name *.DMP -name *.log -mtime +1 -exec rm -f {} \;
else
  echo "BKPLOCATION variable is not set"
fi

