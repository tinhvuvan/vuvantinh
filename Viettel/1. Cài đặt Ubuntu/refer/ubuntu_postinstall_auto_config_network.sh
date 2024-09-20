#!/bin/bash

# default parameter
filename="network_servers.txt";
logfile="log_networkconf_`date +'%Y%m%d%H%M'`.log"

# if get -i with filename, use filename in argument
while getopts i: flag
do
	case "${flag}" in
		i) filename=${OPTARG};;
	esac
done

touch $logfile
echo "Working with file $filename" >> $logfile

# backup netplan config
cp /target/etc/netplan/00-installer-config.yaml /target/etc/netplan/bk_netplan_00_installer_config_yaml_`date +'%Y%m%d%H%M'`

# copy file for working
cp /target/etc/netplan/00-installer-config.yaml /target/root/netplan-config.yaml

# get system serial number
system_serial=`dmidecode -s system-serial-number`
echo "System serial number: ${system_serial}" >> $logfile

# read file
while IFS='|' read -r hostname serial type bond_interface_name bond_subinterfaces bond_macsubinterfaces bond_mode single_interface_name single_macinterface ip_address prefix gateway vlan defroute; do
	# build config command
	command_interface=""
	command_ip=""
	interface_to_use=""
	if [ "$type" = "bond" ] 
	then
		interface_to_use=$bond_interface_name
		subinterfacearray=($(echo $bond_subinterfaces | tr "," "\n"))
		if [[ "$bond_mode" = "4"  ||  "$bond_mode" = "802.3ad" ]]
		then
			# only use mode 4 when config is existed
			command_interface="python3 /target/root/postinstall/networkconf_ubuntu/bonding_config.py --bondiface ${interface_to_use} --physiface ${subinterfacearray[0]},${subinterfacearray[1]} --bondmode 4 --filename /target/root/netplan-config.yaml"
		else
			# default bonding mode is 1 (active-backup)
			command_interface="python3 /target/root/postinstall/networkconf_ubuntu/bonding_config.py --bondiface ${interface_to_use} --physiface ${subinterfacearray[0]},${subinterfacearray[1]} --bondmode 1 --filename /target/root/netplan-config.yaml"
		fi
	else
		# consider default is single config
		interface_to_use=$single_interface_name
		command_interface="python3 /target/root/postinstall/networkconf_ubuntu/single_config.py --physiface ${interface_to_use} --filename /target/root/netplan-config.yaml"
	fi

	if [ "$defroute" = "yes" ] 
	then
		if [ "$vlan" != "none" ] 
		then
			command_ip="python3 /target/root/postinstall/networkconf_ubuntu/vlan_ip_config.py --linkiface ${interface_to_use} --vlan ${vlan} --ipaddr ${ip_address} --ipprefix ${prefix} --ipgateway ${gateway} --filename /target/root/netplan-config.yaml"
		else
			command_ip="python3 /target/root/postinstall/networkconf_ubuntu/novlan_ip_config.py --linkiface ${interface_to_use} --ipaddr ${ip_address} --ipprefix ${prefix} --ipgateway ${gateway} --filename /target/root/netplan-config.yaml"
		fi
	else
		if [ "$vlan" != "none" ] 
		then
			command_ip="python3 /target/root/postinstall/networkconf_ubuntu/vlan_ip_config.py --linkiface ${interface_to_use} --vlan ${vlan} --ipaddr ${ip_address} --ipprefix ${prefix} --filename /target/root/netplan-config.yaml"
		else
			command_ip="python3 /target/root/postinstall/networkconf_ubuntu/novlan_ip_config.py --linkiface ${interface_to_use} --ipaddr ${ip_address} --ipprefix ${prefix} --filename /target/root/netplan-config.yaml"
		fi
	fi

	# Check serial server, wrong serial don't do anything
	if [[ "${serial}" = "${system_serial}" ]]
	then
		echo "Command interface builded: $command_interface" >> $logfile
		echo "Command IP builded: $command_ip" >> $logfile
		eval "$command_interface" 2>&1 | tee $logfile ;
		eval "$command_ip" 2>&1 | tee $logfile ;
		echo "" >> $logfile
	fi

done < <(grep -v "^#\|^$" $filename)

# copy result file to config and done
cp -f /target/root/netplan-config.yaml /target/etc/netplan/00-installer-config.yaml
echo "Complete at `date +'%d-%m-%Y %H:%M:%S'`." >> $logfile
