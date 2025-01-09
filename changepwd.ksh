
#!/bin/ksh

#changepwd.ksh PPMPEBIZ

if [ ${#} -ne 1 ]
then
 echo
 echo "Input DataBase Not Passed - Script Aborting"
 exit 1
fi

# Set DataBase Name
DBName=$1

. /orahome/allu01/aetna/scripts/setupenv.ksh ${DBName} > /dev/null

FILEDIR=/orahome/allu01/aetna/scripts/PPMPEBIZ/
FILENAME=/orahome/allu01/aetna/scripts/PPMPEBIZ/users.txt

while IFS= read -r line
do

username="$line"
#echo $username
cd $FILEDIR
rm -f test.log

sqlplus -s /nolog << EOF
 connect / as sysdba
SPOOL test.log append;
ALTER USER ${username} IDENTIFIED BY "Ac#nGe#d"
/
spool off;
EOF


done <"$FILENAME"
