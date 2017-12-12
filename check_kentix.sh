#!/bin/bash

# Author: Oskar Rittsél, OP5 AB
# Date: 2017-12-12
# Version: 1.0.2


# Add show list of devices

# snmpget is required
SNMPGET=`which snmpget`

# Variables
HOST=
COMMUNITY=
DEVICE=
SENSOR=
WARNING=
CRITICAL=

# Start for supporting both KAM & direct query to a multisensor
KAMOID=".1.3.6.1.4.1.37954.1.2"
MSOID=".1.3.6.1.4.1.37954.2.1"

# Checking against multisensor and not through alarmmanager?
MS=0

usage_text () {

echo -e "Usage:"
echo -e "	./check_kentix.sh -H <hostname> -C <community> -d <device> -s <sensor> -w <warning> -c <critical>"
echo -e "	./check_kentix.sh -m -H <hostname> -C <community> -s <sensor> -w <warning> -c <critical>\n"

}

help_text () {

echo -e "	-h This help text"
echo -e "	-m Check against MultiSensor-LAN and not through AlarmManager"
echo -e "	-l List available devices, requires -H <hostname> -C <community>\n"
echo -e "	-H hostname/IP-address to Kentix AlarmManager"
echo -e "	-C SNMPv2 community name to Kentix AlarmManager"
echo -e "	-d Device ID (integer) of the MultiSensor, found in Kentix ControlCenter or use option -l"
echo -e "	-s Sensor in the MultiSensor"
echo -e "	-w Warning threshold"
echo -e "	-c Critical threshold\n"
echo -e "	Available sensors:\n"
echo -e "	temperature"
echo -e "	humidity"
echo -e "	dewpoint"
echo -e "	co"
echo -e "	motion"
echo -e "	digitalin1"
echo -e "	digitalin2"
echo -e "	digitalout2\n"

echo -e "Examples:"
echo -e "	./check_kentix.sh -H 192.168.0.2 -C public -d 3 -s temperature -w 25 -c 30"
echo -e "	./check_kentix.sh -m -H 192.168.0.3 -C public -s temperature -w 25 -c 30\n"

}


# List all devices - needs $HOST & $COMMUNITY
list_devices () {

DEVICE_NUM=0
DONE=0

while [ $DEVICE_NUM -le 100 ] && [ $DONE = 0 ]; do

	DEVICE_NUM=$(( $DEVICE_NUM + 1 ))

	DEVICE=`$SNMPGET -v2c -c $COMMUNITY $HOST .1.3.6.1.4.1.37954.1.2.$DEVICE_NUM.1.0 | awk -F'STRING: ' '{print $2}'`

	if [ "$DEVICE" == """" ]; then DONE=1
		exit 0
	fi

	echo -e "       $DEVICE_NUM. $DEVICE"

done

}

# Give usage text if no arguments are given
if [ $# -eq 0 ]; then
	usage_text
	exit 0
fi

# Option flags, helptext and set variables.
while getopts ":hlmH:C:d:s:w:c:" opt; do
	case $opt in
		h)
			usage_text
			help_text
			exit 0 
			;;

		H)	HOST=$OPTARG ;;

		C)	COMMUNITY=$OPTARG ;;
		
		d)	DEVICE=$OPTARG ;;

		s)	SENSOR=$OPTARG ;;

		w)	WARNING=$OPTARG ;;

		c)	CRITICAL=$OPTARG ;;

		m)	MS=1 ;;

		\?)
			echo -e "Invalid option: -$OPTARG\n" 
			exit 0
			;;
		:)
			echo -e "Option -$OPTARG requires an argument\n"
			exit 0
			;;
	esac
done

OPTIND=1

# Run it again for listing devices, knowing host & community is set
while getopts ":hlH:C:d:s:w:c:" opt; do
        case $opt in
	l) 
		if [ -z $HOST ] || [ -z $COMMUNITY ]; then

			echo -e "\nUsage: ./check_kentix.sh -H <hostname> -C <community> -l\n"
			echo -e "-H <hostname> -C <community> are required to list devices\n"
			exit 0
		else
		list_devices
		fi
	esac
done

shift "$((OPTIND-1))"


# Set correct OID for the sensor
case "$SENSOR" in
	'temperature')
		SENSORDATA=2 ;;

	'humidity')
		SENSORDATA=3 ;;

	'dewpoint')
		SENSORDATA=4 ;;

	'co')
		SENSORDATA=5 ;;

	'motion')
		SENSORDATA=6 ;;

	'digitalin1')
		SENSORDATA=7 ;;

	'digitalin2')
		SENSORDATA=8 ;;

	'digitalout2')
		SENSORDATA=9 ;;

	*)
		echo "Sensor needs to be one of following: temperature, humidity, dewpoint, co, motion, digitalin1, digitalin2 or digitalout2" 
		exit 3 ;;

esac	

# Checking against multisensor and not through alarmmanager?
if [ $MS -eq 1 ]; then

	# Notify that required argument is missing
	if [ -z "$HOST" ] || [ -z "$COMMUNITY" ] || [ -z "$SENSOR" ] || [ -z "$WARNING" ] || [ -z "$CRITICAL" ]; then

		echo -e "\nUsage: ./check_kentix.sh -m -H <hostname> -C <community> -s <sensor> -w <warning> -c <critical>\n"
		echo -e "Missing parameters!\n"
		exit 3
	fi

	# Sensor ID is not the same on MultiSensor as in AlarmManager
	SENSORDATA=$(($SENSORDATA-1))

	# If temperature, humidity or dewpoint, divide by 10
	if [[ ( $SENSORDATA -eq 1 ) || ( $SENSORDATA -eq 2 ) || ( $SENSORDATA -eq 3 ) ]]; then

        	DATA=`$SNMPGET -v2c -c $COMMUNITY $HOST $MSOID.$SENSORDATA.1.0 | awk '{print $NF/10}'`
	else
        	DATA=`$SNMPGET -v2c -c $COMMUNITY $HOST $MSOID.$SENSORDATA.1.0 | awk '{print $NF}'`
	fi

else

	# Notify that required argument is missing
	if [ -z "$HOST" ] || [ -z "$COMMUNITY" ] || [ -z "$DEVICE" ] || [ -z "$SENSOR" ] || [ -z "$WARNING" ] || [ -z "$CRITICAL" ]; then

		echo -e "\nUsage: ./check_kentix.sh -H <hostname> -C <community> -d <device> -s <sensor> -w <warning> -c <critical>\n"
		echo -e "Missing parameters!\n"
		exit 3
	fi

	# If temperature, humidity or dewpoint, divide by 10
	if [[ ( $SENSORDATA -eq 2 ) || ( $SENSORDATA -eq 3 ) || ( $SENSORDATA -eq 4 ) ]]; then

		DATA=`$SNMPGET -v2c -c $COMMUNITY $HOST $KAMOID.$DEVICE.$SENSORDATA.0 | awk '{print $NF/10}'`

	else
		DATA=`$SNMPGET -v2c -c $COMMUNITY $HOST $KAMOID.$DEVICE.$SENSORDATA.0 | awk '{print $NF}'`
	fi
fi


# Check if we're above threshold - done with python because of floaters.
if python -c "import sys; sys.exit(0 if float($DATA) >= float($CRITICAL) else 1)"; then
	echo "CRITICAL - $SENSOR $DATA is above $CRITICAL | $SENSOR=$DATA;$WARNING;$CRITICAL"
	exit 2
elif python -c "import sys; sys.exit(0 if float($DATA) >= float($WARNING) else 1)"; then
	echo "WARNING - $SENSOR $DATA is above $WARNING | $SENSOR=$DATA;$WARNING;$CRITICAL"
	exit 1
else
	echo "OK - $SENSOR is $DATA | $SENSOR=$DATA;$WARNING;$CRITICAL"
	exit 0
fi
