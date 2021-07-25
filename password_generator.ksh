#!/bin/ksh

###Generic functions

function usage {
  echo ""
  echo "Usage: password_gen2.ksh -n <Number of Passwords> "
  echo ""
  echo " n: Number of Passwords"
  echo ""
  exit 1
}

function check_input {
  [ -z "${NUM_PASS}" ] && usage
}


###Password generator function
###25 character password gets generated 

function password_gen {
    char_set="abcdefghijklmonpqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
    sp_char_set="!#^*$()"
    n=25
    rand=""
        for i in `seq 1 $n`; do
            char=${char_set:$RANDOM % ${#char_set}:1}
             rand=$char$rand
        done
        
    ##special chracter was added to the end

    sp_char=${sp_char_set:$RANDOM % ${#sp_char_set}:1}
    echo $rand$sp_char
}

 

# main menu


while getopts n: option
do
    case ${option} in
        n )  NUM_PASS="${OPTARG}";;
        \?) usage
    esac
done

check_input

password_count=`echo "${NUM_PASS}"`

###echo $password_count
###calling password fucntion through a loop
###loops till the user entered number

echo ""
echo "========================================"
echo "Generating $password_count Passwords Now"
echo "========================================"
echo ""

 
for ((n=1; n<=password_count; n++))
do
###calling password func
echo "Password [$n]  Generated : " `password_gen`
done
echo ""
