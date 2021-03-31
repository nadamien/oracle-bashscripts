#!/bin/ksh
###############################################################################
#                                                                             #                                 
# Purpose: Guided Site Failover (DR Activity)                                 #
# Inputs : taken via command can be used with Oracle DG                       #
# Created By : Pasindu W                                                      #
###############################################################################

export ORACLE_SID=TESTSID
export ORACLE_HOME=/u01/app/oracle/product/12.1.0.2/dbhome_1
export PATH=$PATH:$ORACLE_HOME/bin

###Generic functions

function usage {
  echo ""
  echo "Usage: site_failover.ksh -s <SOURCE_db_unique_name> -d <DESTINATION_db_unique_name> -p <SYS Password>"
  echo ""
  echo " s: PRIMARY DB Unique Name"
  echo " d: FAILOVER DB Unique Name"
  echo " p: SYS Password"
  echo ""
  exit 1
}


function check_input {
  [ -z "${IN_DB_UNIQUE_NAME}" -o -z "${IN_STB_DB_UNIQUE_NAME}" -o -z  "${PASS_W}" ]&& usage
}


function bct_update {
      sqlplus -S "/ as sysdba"<< EOF
      SET SERVEROUTPUT OFF
      set lines 200 pages 200
      col name for a20
      col open_mode for a30
      col database_role for a30
      col FILENAME for a50
      col status for a40
      select NAME,OPEN_MODE,database_role from gv\$database;
      set heading off
      select 'Current BCT Statys' from dual;
      set heading on
      select filename, status from  v\$block_change_tracking;
      ALTER DATABASE DISABLE BLOCK CHANGE TRACKING;
      set heading off
      select 'New BCT Status' from dual;
      set heading on
      select filename, status from  v\$block_change_tracking;
      exit
EOF
}

##Switch over function 

function dg_switch {
  dgmgrl -echo << EOF
  connect sys/'$sys_pass'
  switchover to '$db_unq_nm_sc';
  show configuration;
  exit
EOF
}


# main menu
while getopts s:d:p: option
do
    case ${option} in
        s )  IN_DB_UNIQUE_NAME="${OPTARG}";;
                d )  IN_STB_DB_UNIQUE_NAME="${OPTARG}";;
        p )  PASS_W="${OPTARG}";;
        \? ) usage
    esac
done

check_input

host_set=`hostname`

###Formating Picked DB Unique Names
db_unq_nm_uc=`echo "${IN_DB_UNIQUE_NAME}" | tr [a-z] [A-Z]`
db_unq_nm_sc=`echo "${IN_STB_DB_UNIQUE_NAME}" | tr [a-z] [A-Z]`
sys_pass=`echo "${PASS_W}"`
host=`echo $host_set`
len=${#db_unq_nm_uc}-1
source_me=`echo "${db_unq_nm_uc:0: $len}"`

##Sequintial logic steps

echo "Database Picked:" $ORACLE_SID
echo ''
echo "Logged in host :" $host
echo ''
echo "Database Unique Name of PRIMARY[Source]:" $db_unq_nm_uc
echo ''
echo "Database Unique Name of STANDBY[Destination]:" $db_unq_nm_sc
echo ''
echo  'Is the bellow picked database correct ? '
echo  "Press [ENTER] to continue"
echo ''
read db_input
echo ''
echo "DB Unique Name :" $db_unq_nm_uc
echo "Logged in host :" $host
echo ''
echo '=================================================='
echo '= RUNNING Pre-Checks Before Site Switch          ='
echo '=================================================='
echo ''
echo "Current Configuration For :" $db_unq_nm_uc
echo ''
dgmgrl  sys/'$sys_pass' "show configuration;"
echo ''
echo "Validating Database" $db_unq_nm_uc
echo ''
dgmgrl  sys/'$sys_pass' "validate database '$db_unq_nm_uc'"
echo ''
echo "Validating Database" $db_unq_nm_sc
dgmgrl  sys/'$sys_pass' "validate database '$db_unq_nm_sc'"
echo ''
echo  'If validation is succefull '
echo  "Press [ENTER] to continue"
echo ''
echo ''
read db_input
echo ''
echo '================================================='
echo '= DISABLING BCT Now                             ='
echo '================================================='

##calling BCT update

bct_update

echo "Current Configuration For :" $db_unq_nm_uc
echo ''
dgmgrl  sys/'$sys_pass' "show configuration;"
echo ''
echo  'If BCT is Disabled and Check Current Standby Status is Good '
echo  "Press [ENTER] to continue"
echo ''
read db_input
echo ''
echo '==================================================='
echo '= Proceeding With Site Switch to ' $db_unq_nm_sc
echo '==================================================='
echo  "Press [ENTER] to continue"
echo ''
read db_input
echo ''
echo "Switching-Over to " $db_unq_nm_sc
echo ''

###calling switchover function

dg_switch

echo ''
echo '=============================================================================='
echo ' Please do POST - CHECKS '
echo '=============================================================================='
echo ''
echo ''
exit 0