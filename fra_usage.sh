#!/bin/bash
#script          : fra_usage.sh
#description     : Display the FRA usage
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
EOF
