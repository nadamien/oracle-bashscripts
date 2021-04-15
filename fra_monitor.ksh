#!/bin/ksh
###############################################################################
#                                                                             #                                 
#                                                                             #
# Purpose: Internal Script to notify FRA space issue                          #
# Can be used for some DEV/TEST env where                                     #
# alerting is not setup                                                       #
#                                                                             #
# Created By - Pasindu W                                                      #
###############################################################################

###setting up the enviornment

export ORACLE_SID=TESTSID
export ORACLE_HOME=/u01/app/oracle/product/12.1.0.2/dbhome_1
export PATH=$PATH:$ORACLE_HOME/bin
export sysdat=$(date +"%d%m%Y")

### main function
func_fra_mon()
{
for sid in "${db_list[@]}"
do
used_perc=`sqlplus -s 'uname/pass'@$sid <<EOF
SET PAGESIZE 0 FEEDBACK OFF VERIFY OFF HEADING OFF ECHO OFF TRIMOUT ON
select sum(percent_space_used) from v\\$flash_recovery_area_usage;
EXIT;
EOF`
if [[ $used_perc -gt 77 ]]
then
        echo $sid "Fra is Filled Upto" $used_perc >> /nfs/oradump_dba/pasindu/fra_mon/fra_usg_$sysdat.txt
        sqlplus -s <ssyspriv_user>/<pass>@$sid @/nfs/oradump_dba/pasindu/fra_mon/perc_fra.sql >> /nfs/oradump_dba/pasindu/fra_mon/fra_usg_$sysdat.txt
        func_send_alert;
        ####elimanted duplication
        func_housekeep;
else
        echo $sid "Fra is good" $used_perc
fi
echo $used_perc
done;
}

###generic functions
####main function call to initilize database name array and textfile in use

func_init()
###initilize text file
touch  /nfs/oradump_dba/pasindu/fra_mon/fra_usg_$sysdat.txt
### initilize database name array
### please note TNS entries should be in and ideally this script should be implemented on the central server with connection to all the databses
db_list=( SID_A SID_B SID_C SID_D SID_E )
}

func_send_alert ()
{
export MAIL_LIST="pasindu8@gmail.com"
(
        echo "From: DBA Oracle";
        echo "To: ${MAIL_LIST}";
        echo "Subject: FRA is over 78% Filled on $sid Please Check!!!!! ";
         cat /nfs/oradump_dba/pasindu/fra_mon/mailheader.txt  /nfs/oradump_dba/pasindu/fra_mon/fra_usg_$sysdat.txt /nfs/oradump_dba/pasindu/fra_mon/mailfooter.txt
) | /usr/sbin/sendmail -t
}

func_housekeep()
{
rm /nfs/oradump_dba/pasindu/fra_mon/fra_usg_$sysdat.txt
}

##function calls

func_init;
func_fra_mon;
func_housekeep;

exit 0
