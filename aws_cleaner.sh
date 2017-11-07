#!/bin/bash

deleting_snapshots(){
aws ec2 delete-snapshot --snapshot-id ${ARRAY_SNAPSHOTS_ID[$COUNT]};((DELETED++))
}

usage() {
  echo " ** please run 'aws configure' before to set your information"
  echo "------------------CLEANING EBS SNAPSHOTS---------------------"
  echo "        Usage: "
  echo "         -i instance "
  echo "         -u user"
  echo "         -k key pair path"
  echo "         -a account id"
  echo "        Example: ./aws_cleaner.sh -i 18.221.71.250 -u ubuntu -k /home/jegonzalez/jegonzalez_key_pair.pem -a 605271135585"
  exit 0
}


while getopts "i:u:k:a:" option ; do
  case $option in
     i ) INSTANCE=$OPTARG ;;
     u ) USER=$OPTARG;;
     k ) KEY_PATH=$OPTARG ;;
     a ) ACCOUNT_ID=$OPTARG ;;
    * ) usage ; exit 0 ;;
  esac
done

if [ "$#" -lt 1 ]
then
 usage
fi

while [ -z $ACCOUNT_ID ];do
	read -p "ACCOUNT_ID: " ACCOUNT_ID
done
TODAY=$( ssh -i ${KEY_PATH} ${USER}@${INSTANCE} date +%Y%m%d )
YESTERDAY=$(ssh -i ${KEY_PATH} ${USER}@${INSTANCE} date +%Y%m%d%HH%MM%SS -d "yesterday"|sed 's/[HMS]//g')
COUNT=0
DELETED=0

###### ignoring 15th-day-of-each-month-snapshots ######
echo -e "Cleaning space...\n"
SNAPSHOTS_DESCRIPTION=$(aws ec2 describe-snapshots --owner-ids ${ACCOUNT_ID} --output text |grep -vi backup_......15000000|awk '{print $2}'|sed 's/.*\(backup_\)//')
SNAPSHOTS_ID=$(aws ec2 describe-snapshots --owner-ids ${ACCOUNT_ID} --output text |grep -vi backup_......15000000|sed 's/.*\(snap\)/\1/'|awk '{print $1}' )
ARRAY_SNAPSHOTS_ID=(${SNAPSHOTS_ID})

####### erasing all except the last 24 hours
for i in $( echo ${SNAPSHOTS_DESCRIPTION} );do
	[[ ${i} < ${YESTERDAY} ]] && deleting_snapshots
	((COUNT++))
done

LIST_CLEAN=$(aws ec2 describe-snapshots --owner-id 605271135585 --output text|wc -l)

# creating report
echo "${LIST_CLEAN} snapshots have been saved and ${DELETED} have been deleted"
