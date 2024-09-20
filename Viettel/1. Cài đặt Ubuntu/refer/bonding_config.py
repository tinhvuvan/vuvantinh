#!/usr/bin/python3
import sys
import argparse
import yaml
import ipaddress

# load yaml config of interfaces
def load_config(netplan_config_filename):
    with open(netplan_config_filename, "r") as stream:
        try:
            netplan_config = yaml.safe_load(stream)
        except yaml.YAMLError as ex:
            print(ex)
            return "ERROR"
    
    print(netplan_config)
    return netplan_config

# place new config
def place_config(netplan_config, physiface, bondiface, bondmode, ipaddr, ipprefix, ipgateway):
    # precheck something
    print("Writing bonding interface " + bondiface + " with child physical interface " + str(physiface) + " and mode " + bondmode)
    newbond = {
        "dhcp4": False,
        "dhcp6": False,
        "interfaces": physiface
    }

    # build parameters for mode 802.3ad
    if (bondmode == "4") or (str.lower(bondmode) == "802.3ad"):
        newbond["parameters"] = {
            "mode": "802.3ad",
            "lacp-rate": "fast",
            "mii-monitor-interval": 100,
            "transmit-hash-policy": "layer3+4"
        }
    # build parameters for mode active-backup
    elif (bondmode == "1") or (str.lower(bondmode) == "active-backup"):
        newbond["parameters"] = {
            "mode": "active-backup",
            "mii-monitor-interval": 100
        }
    # any others mean error
    else:
        print("Error while building bonding config. Please try again.")
        return "ERROR"

    # for config ip address of bonding interface
    try:
        ip = ipaddress.ip_address(ipaddr)
        mask = int(ipprefix)
        if (mask > 0) and (mask < 32):
            newaddress = str(ipaddr + "/" + ipprefix)
            newbond["addresses"] = [newaddress]
    except:
        print("Empty or invalid IP address type. Ignoring config IP address for this connection.")
        pass    
    # for config default gateway
    try:
        ipgw = ipaddress.ip_address(ipgateway)
        newbond["routes"] = [{
            "to": "default",
            "via": ipgateway
        }]
    except:
        print("Empty or invalid IP gateway address type. This interface will have no gateway config.")
        pass    

    # everything is ok, now add or replace current config
    # if any bonding or physical interface exists, replace it
    # init bonding entry if do not exists
    if "bonds" not in netplan_config["network"]:
        netplan_config["network"]["bonds"] = {}
        
    netplan_config["network"]["bonds"][bondiface] = newbond
    for iface in physiface:
        netplan_config["network"]["ethernets"][iface] = {"dhcp4": False}

    print("New config: ")
    print(yaml.dump(netplan_config, default_flow_style=False, sort_keys=False))
    return netplan_config


# write new config to file
def write_config(netplan_config, netplan_config_filename):
    with open(netplan_config_filename, "w+") as file:
        try:
            netplan_written = yaml.dump(netplan_config, file, default_flow_style=False, sort_keys=False)
        except yaml.YAMLError as ex:
            print(ex)
            return "ERROR"

    return netplan_written


# main program
def main(argv):
    # parse arguments
    parser = argparse.ArgumentParser(argument_default=argparse.SUPPRESS)
    parser.add_argument('--physiface', dest='physiface', help='Input your physical interface here, delimiting by comma. Mandatory.')
    parser.add_argument('--bondiface', dest='bondiface', help='Input your bonding interface here. Mandatory.')
    parser.add_argument('--bondmode', dest='bondmode', help='Input your bonding mode here. Mandatory.')
    parser.add_argument('--ipaddr', dest='ipaddr', help='Input your IP address here. Optional.')
    parser.add_argument('--ipprefix', dest='ipprefix', help='Input your IP prefix here. Optional.')
    parser.add_argument('--ipgateway', dest='ipgateway', help='Input your IP gateway here. Optional.')
    parser.add_argument('--filename', dest='filename', help='Input your file name to config here. Default uses file netplan-config.yaml in active folder.')

    args = parser.parse_args()

    physiface = []
    bondiface = ""
    bondmode = ""
    ipaddr = ""
    ipprefix = ""
    ipgateway = ""
    filename = "netplan-config.yaml"

    # get file name in arguments, if no argument use default file
    try:
        filename = str(args.filename)
        print("Use config file: " + filename)
    except Exception:
        filename = "netplan-config.yaml"
        print("No config file name in arguments or error. Use default file netplan-config.yaml.")

    # 3 tham so physiface, bondiface, bondmode phai co, neu ko thi ko chay
    try:
        physiface = str(args.physiface).split(',')
        bondiface = str(args.bondiface)
        bondmode = str(args.bondmode)
    except Exception:
        print("Error occured. Require at least 3 parameters: physiface, bondiface, bondmode. Please rerun the command with proper parameters.")
        return 1
    
    # chi bond cho 2 interface
    if (len(physiface) != 2):
        print("Only accept 2 physical interfaces at the moment. Please try again with comma delimiter.")
        return 1
    
    # chi bond mode 1 va mode 4
    if (bondmode != "4") and (bondmode != "1") and (str.lower(bondmode) != "802.3ad") and (str.lower(bondmode) != "active-backup"):
        print("Only accept bond mode 1 (active-backup) or bond mode 4 (802.3ad). Please try again.")
        return 1

    # load cau hinh ip, tham so nay neu ko co cung duoc
    try:
        ipaddr = str(args.ipaddr)
        ipprefix = str(args.ipprefix)
        ipgateway = str(args.ipgateway)
    except Exception:
        pass
    
    # load config
    netplan_current_config = load_config(filename)
    if netplan_current_config == "ERROR":
        print("Error when loading network config.")
        return 1
    
    # config new interfaces
    netplan_new_config = place_config(netplan_current_config, physiface, bondiface, bondmode, ipaddr, ipprefix, ipgateway)
    if (netplan_new_config == "ERROR"):
        print("Error while creating new config.")
        return 1
    
    netplan_write_config = write_config(netplan_new_config, filename)
    if (netplan_write_config == "ERROR"):
        print("Error while write config to file.")
        return 1

    print("Write new config OK.")

if __name__ == "__main__":
    main(sys.argv[0:])