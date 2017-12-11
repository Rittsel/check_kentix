# check_kentix

Nagios / Naemon plugin to monitor Kentix Multisensor with AlarmManager.
This plugin aims to monitor Kentix MultiSensors either through Kentix AlarmManager or directly against MultiSensor-LAN.

## Installation

The plugin requires snmpget binary.

CentOS, RHEL 6/7.
```sh
# yum install net-snmp-utils
```

## Usage

The plugin can query the AlarmManager or MultiSensor-LAN with option "-m"

```sh
Usage:
        ./check_kentix.sh -H <hostname> -C <community> -d <device> -s <sensor> -w <warning> -c <critical>
        ./check_kentix.sh -m -H <hostname> -C <community> -s <sensor> -w <warning> -c <critical>
```

**List devices**

To list devices available in the AlarmManager option "-l" can be used.
This will list available devices together with ID (integer) of each device used with option "-d".

```sh
$ ./check_kentix.sh -l -H <hostname> -C <community>
```

**Sensors**

The plugin can query all the available sensors

```sh
temperature
humidity
dewpoint
co
motion
digitalin1
digitalin2
digitalout2
```

**Example output**
```sh
$ ./check_kentix.sh -H XXX.XXX.XXX.XXX -C public -d 3 -s temperature -w 25 -c 30
CRITICAL - temperature 31.7 is above 30 | temperature=31.7
```

### Available arguments

```sh
$ ./check_kentix.sh -h
Usage:
        ./check_kentix.sh -H <hostname> -C <community> -d <device> -s <sensor> -w <warning> -c <critical>
        ./check_kentix.sh -m -H <hostname> -C <community> -s <sensor> -w <warning> -c <critical>

        -h This help text
        -m Check against MultiSensor-LAN and not through AlarmManager
        -l List available devices, requires -H <hostname> -C <community>

        -H hostname/IP-address to Kentix AlarmManager
        -C SNMPv2 community name to Kentix AlarmManager
        -d Device ID (integer) of the MultiSensor, found in Kentix ControlCenter or use option -l
        -s Sensor in the MultiSensor
        -w Warning threshold
        -c Critical threshold

        Available sensors:

        temperature
        humidity
        dewpoint
        co
        motion
        digitalin1
        digitalin2
        digitalout2

Examples:
        ./check_kentix.sh -H 192.168.0.2 -C public -d 3 -s temperature -w 25 -c 30
        ./check_kentix.sh -m -H 192.168.0.3 -C public -s temperature -w 25 -c 30

