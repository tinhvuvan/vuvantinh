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
def place_config(netplan_config, physiface, ipaddr, ipprefix, ipgateway):
    # precheck something
    print("Writing physical interface " + str(physiface))
    newiface = {
        "dhcp4": False
    }

    # for config ip address of bonding interface
    try:
        ip = ipaddress.ip_address(ipaddr)
        mask = int(ipprefix)
        if (mask > 0) and (mask < 32):
            newaddress = str(ipaddr + "/" + ipprefix)
            newiface["addresses"] = [newaddress]
    except:
        print("Empty or invalid IP address type. Ignoring config IP address for this connection.")
        pass    
    # for config default gateway
    try:
        ipgw = ipaddress.ip_address(ipgateway)
        newiface["routes"] = [{
            "to": "0.0.0.0/0",
            "via": ipgateway
        }]
    except:
        print("Empty or invalid IP gateway address type. This interface will have no gateway config.")
        pass    

    # everything is ok, now add or replace current config
    # if any physical interface exists, replace it
    netplan_config["network"]["ethernets"][physiface] = newiface

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
    parser.add_argument('--physiface', dest='physiface', help='Input your physical interface here. Mandatory.')
    parser.add_argument('--ipaddr', dest='ipaddr', help='Input your IP address here. Optional.')
    parser.add_argument('--ipprefix', dest='ipprefix', help='Input your IP prefix here. Optional.')
    parser.add_argument('--ipgateway', dest='ipgateway', help='Input your IP gateway here. Optional.')
    parser.add_argument('--filename', dest='filename', help='Input your file name to config here. Default uses file netplan-config.yaml in active folder.')

    args = parser.parse_args()

    physiface = ""
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

    # tham so physiface phai co, neu ko thi ko chay
    try:
        physiface = str(args.physiface)
    except Exception:
        print("Error occured. Require at least physiface. Please rerun the command with proper parameters.")
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
    netplan_new_config = place_config(netplan_current_config, physiface, ipaddr, ipprefix, ipgateway)
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