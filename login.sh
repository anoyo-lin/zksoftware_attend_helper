#!/bin/bash
SQL="sqlite3"
function info() {
	echo "Usage:"
	echo "./login.sh checkin [employee's ID] [2017-12-31]"
	echo "./login.sh checkout [employee's ID] [2017-12-31]"
	echo "	add a AM or PM record with specified date, if date was not defined, date will be fixed to current date"
	echo "./login.sh change [employee's ID] [2017-12-31]"
	echo "	it will show current&before month records of defined employee'ID, you can select a record id, "
	echo "	script will fixed record to AM or PM automatically. date is optional parameter."
	echo "	if defined it will change date of selected record."
	echo "./login.sh help [helper's ID] [helped's ID] [finger's number]"
	echo "	remap helper's finger print ID to helped employee, [finger's number] is optional parameter."
	echo "	if finger number defined will replace selected finger print for helped employee"
	echo "	leftest to righitest finger starts with 1 to 10. "
	echo "./login.sh cancel"
	echo "	it will show a help history list you modified before, you can input a selected record. "
	echo "	and remap finger print from helped back to helper. "
	echo "./login.sh seq"
	echo "	it will re-order the primary-key of att_log, and make the records' id correctly. "
}
declare pre_mon 
function previous() {
	if [[ $1 == "" ]];then
		cnt=1
	else
		cnt=$1
	fi
	year=`date +%Y`
	month=`date +%m`
	if [[ `echo $month|cut -b 1` == 0 ]];then
		if [[ $((`echo $month|cut -b 2`-1)) == 0 ]];then
			pre_mon=$((year-$cnt))"-12"
		else
			pre_mon=$year"-0"$((`echo $month|cut -b 2`-$cnt))
		fi
	elif [[ `echo $month|cut -b 2` == 0 ]];then
		pre_mon=$year"-0"$((month-$cnt))
	else
		pre_mon=$year"-"$((month-$cnt))
	fi
}
function check_id() {
	if echo $1|grep -Eq "^[0-9]+$";then
		return 0
	else
		echo "please insert correct numberic ID, exit!"
		return 1
	fi
}
function check_date() {
	if echo $1|grep -Eq "^[0-9]{4}-[0-9]{2}-[0-9]{2}$";then
		year=`echo $1|awk -F \- '{print $1}'`
		month=`echo $1|awk -F \- '{print $2}'`
		date=`echo $1|awk -F \- '{print $3}'`
		max_day=0
		case $month in
			01|03|05|07|08|10|12)
				max_day=31
				;;
			04|06|09|11)
				max_day=30
				;;
			02)
				if [[ `expr $year % 4` == 0 || `expr $year % 100` == 0 || `expr $year % 400` == 0 ]];then
					max_day=29
				else
					max_day=28
				fi
		esac
		if [ $date -le $max_day -a $date -ne 0 ];then
			return 0
		else
			echo "wrong date format,defined date will replace by original date!"
			return 1
		fi
	else
		echo "wrong date format,defined date will replace by original date!"
		return 1
	fi
}
function rand() {
	local beg=$1
	local end=$2
	echo $(( RANDOM % ( $end - $beg ) + $beg ))
}
function query() {
	id=`${SQL} ZKDB.db "SELECT User_PIN FROM USER_INFO WHERE User_PIN = '$1'"`
	if [ "${id}" == "" ]; then
		echo "can not find employee in USER_INFO you input, exit!"
		return 0
	fi
	${SQL} ZKDB.db ".quit"
	echo "the employee in USER_INFO you input exist! It is ${id}"
	return 1
}
function query_rec() {
	id=`${SQL} ZKDB.db "SELECT ID FROM ATT_LOG WHERE Verify_Time LIKE '${mon}%' AND User_PIN = '$2' AND ID = '$1';"`
	if [ "${id}" == "" ]; then
		id=`${SQL} ZKDB.db "SELECT ID FROM ATT_LOG WHERE Verify_Time LIKE '${pre_mon}%' AND User_PIN = '$2' AND ID = '$1';"`
		if [ "${id}" == "" ]; then		
			echo "can not find record in ATT_LOG you input, exit!"
			return 0
		fi
	fi
	${SQL} ZKDB.db ".quit"
	echo "the record in ATT_LOG you input exist! It is ${id}"
	return 1
}
function checkin() {
	id=$1
	if ! check_id $id || query $id;then exit;fi
	if check_date $2; then
		rand_time=$2"T""08:"$(rand 35 59)":"$(rand 10 59)		
	else
		rand_time=$(date '+%Y-%m-%d')"T""08:"$(rand 35 59)":"$(rand 10 59)
	fi
	${SQL} ZKDB.db "INSERT INTO ATT_LOG VALUES (null,'${id}',1,'${rand_time}','255','0',null,null,null,null,0);"
	echo "added successful,the result is ID,User_PIN,Verify_Time"
	${SQL} ZKDB.db "SELECT ID,User_PIN,Verify_Time FROM ATT_LOG WHERE User_PIN = '${id}' ORDER BY ID DESC LIMIT 1"
	${SQL} ZKDB.db ".quit"
}
function checkout() {
	id=$1
	if ! check_id $id || query $id;then exit;fi
	if check_date $2; then
		rand_time=$2"T""17:"$(rand 35 59)":"$(rand 10 59)		
	else
		rand_time=$(date '+%Y-%m-%d')"T""17:"$(rand 35 59)":"$(rand 10 59)
	fi
	${SQL} ZKDB.db "INSERT INTO ATT_LOG VALUES (null,'${id}',1,'${rand_time}','255','0',null,null,null,null,0);"
	echo "added successful,the result is ID,User_PIN,Verify_Time"
	${SQL} ZKDB.db "SELECT ID,User_PIN,Verify_Time FROM ATT_LOG WHERE User_PIN = '${id}' ORDER BY ID DESC LIMIT 1"
	${SQL} ZKDB.db ".quit"
}	
function change() {
	id=$1
	if ! check_id $id || query $id;then exit;fi
	
	mon=$(date '+%Y-%m')
	previous 
	echo "the record list latter displayed are data contained the whole current month "
	${SQL} ZKDB.db "SELECT ID,User_PIN,Verify_Time FROM ATT_LOG WHERE User_PIN = '${id}' AND Verify_Time LIKE '${pre_mon}%';"
	${SQL} ZKDB.db "SELECT ID,User_PIN,Verify_Time FROM ATT_LOG WHERE User_PIN = '${id}' AND Verify_Time LIKE '${mon}%';"
	read -p "please insert record id from ${id} employee:" rec
	if ! check_id $rec || query_rec $rec $id;then exit;fi 
	${SQL} ZKDB.db "SELECT Verify_Time FROM ATT_LOG WHERE ID = '${rec}';" > old_time
	if [[ $(sed -n 's/\(^20.*\)T\([0-9][0-9]\):.*/\2/p' old_time) > 12 ]] && check_date $2;then
		rand_time=$2"T""17:"$(rand 35 59)":"$(rand 10 59)
	elif [[ $(sed -n 's/\(^20.*\)T\([0-9][0-9]\):.*/\2/p' old_time) > 12 ]];then
		rand_time=$(sed -n 's/\(^20.*\)T\([0-9][0-9]\):.*/\1/p' old_time)"T""17:"$(rand 35 59)":"$(rand 10 59)
	elif check_date $2;then
		rand_time=$2"T""08:"$(rand 35 59)":"$(rand 10 59)
	else
		rand_time=$(sed -n 's/\(^20.*\)T\([0-9][0-9]\):.*/\1/p' old_time)"T""08:"$(rand 35 59)":"$(rand 10 59)
	fi
	rm old_time
	${SQL} ZKDB.db "UPDATE ATT_LOG SET Verify_Time = '${rand_time}' WHERE ID = '${id}';"
	echo "modified successful, the result is ID,User_PIN,Verify_Time"
	${SQL} ZKDB.db "SELECT ID,User_PIN,Verify_Time FROM ATT_LOG WHERE ID = '${id}';"
	${SQL} ZKDB.db ".quit"
}
function help() {
	if ! check_id $1 || ! check_id $2 || query $1 || query $2;then exit;fi
	if [[ $1 == $2 ]];then
		echo "please make helper&helped personnel with different people, exit!"
		exit
	fi
	if [[ $3 == "" ]];then
		finger=7
	elif check_id $3 && [ $3 -le 10 -a $3 -gt 0 ];then
		finger=$3
	else
		echo "please insert finger_number between 1 and 10, exit!"
		exit
	fi
	helper=$1
	helped=$2
	helper_id=`${SQL} ZKDB.db "SELECT ID FROM USER_INFO WHERE User_PIN = '${helper}';"`
	helped_id=`${SQL} ZKDB.db "SELECT ID FROM USER_INFO WHERE User_PIN = '${helped}';"`
	helper_finger_id=`${SQL} ZKDB.db "SELECT ID FROM fptemplate10 WHERE pin = '${helper_id}' AND fingerid = '${finger}';"`
	if [[ $helper_finger_id == "" ]];then	
		echo "helper: [$helper] can not help helped: [$helped] by using finger: [$finger] to attendence,please try other helper or other finger, exit! "
		exit
	else
		echo $helper_finger_id $helper $helped >> help_list
		echo "helper: [$helper] 's finger: [$finger]; record: [$helper_finger_id] will change the ownership to helped: [$helped]."
		${SQL} ZKDB.db "UPDATE fptemplate10 SET pin = '${helped_id}' WHERE ID = '${helper_finger_id}';"
	fi
	${SQL} ZKDB.db ".quit"
}
function cancel_help() {
	if [[ `cat help_list` == "" ]];then
		echo "there is no records in help_list, exit!"
		exit
	else
		echo "finger_record, helper, helped."
		cat help_list
		read -p "which help_finger_record will you cancel?" rec
		if ! check_id $rec;then exit;fi
		helper=`sed -n "/^${rec} .*/p" help_list|awk '{print $2}'`
		helped=`sed -n "/^${rec} .*/p" help_list|awk '{print $3}'`
		if [[ $helper == "" ]];then 
			echo "please insert correct record_id, exit!"
			exit
		fi
		helper_id=`${SQL} ZKDB.db "SELECT ID FROM USER_INFO WHERE User_PIN = '${helper}';"`
		helped_id=`${SQL} ZKDB.db "SELECT ID FROM USER_INFO WHERE User_PIN = '${helped}';"`
		echo "helper: [$helper] 's record: [$rec] will revert back from helped: [$helped] to helper: [$helper]."
		${SQL} ZKDB.db "UPDATE fptemplate10 SET pin = '${helper_id}' WHERE ID = '${rec}' AND pin = '${helped_id}';"
		sed -n "/${rec}/dp" help_list > temp && mv temp help_list
		${SQL} ZKDB.db ".quit"
	fi		
}
function seq() {
	new_id=$1
	for old_id in `${SQL} ZKDB.db "select id from att_log order by verify_time asc"`
	do
		${SQL} ZKDB.db "update att_log set id = $new_id where id = $old_id"
		let new_id+=1
	done
	${SQL} ZKDB.db ".quit"
}

function Usage() {
	while [ $# != 0 ]
	do
		case $1 in 
			"checkin" )
				checkin $2 $3
				exit
			;;
			"checkout" )
				checkout $2 $3
				exit
			;;
			"change" )
				change $2 $3
				exit
			;;
			"help" )
				help $2 $3 $4
				exit
			;;
			"cancel" )
				cancel_help
				exit
			;;
			"seq" )
				seq 100001
				seq 1
				exit
			;;
			* )
				info
				exit
		esac
	done
	if [[ $# == 0 ]];then
		info
		exit
	fi
}
Usage "$@"
