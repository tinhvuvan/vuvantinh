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
def place_config(netplan_config, linkiface, ipaddr, ipprefix, ipgateway):
    # precheck something
    print("Writing to interface " + str(linkiface))

    # if interface is physical
    if linkiface in netplan_config["network"]["ethernets"]:
        # for config ip address of interface
        try:
            ip = ipaddress.ip_address(ipaddr)
            mask = int(ipprefix)
            if (mask > 0) and (mask < 32):
                newaddress = str(ipaddr + "/" + ipprefix)
                netplan_config["network"]["ethernets"][linkiface]["addresses"] = [newaddress]
        except:
            print("Empty or invalid IP address type.")
            return "ERROR"
        # for config default gateway
        try:
            ipgw = ipaddress.ip_address(ipgateway)
            netplan_config["network"]["ethernets"][linkiface]["gateway4"] = ipgateway
        except:
            print("Empty or invalid IP gateway address type. This interface will have no gateway config.")
            pass
    # if interface is bond
    elif linkiface in netplan_config["network"]["bonds"]:
        # for config ip address of interface
        try:
            ip = ipaddress.ip_address(ipaddr)
            mask = int(ipprefix)
            if (mask > 0) and (mask < 32):
                newaddress = str(ipaddr + "/" + ipprefix)
                netplan_config["network"]["bonds"][linkiface]["addresses"] = [newaddress]
        except:
            print("Empty or invalid IP address type.")
            return "ERROR"
        # for config default gateway
        try:
            ipgw = ipaddress.ip_address(ipgateway)
            netplan_config["network"]["bonds"][linkiface]["gateway4"] = ipgateway
        except:
            print("Empty or invalid IP gateway address type. This interface will have no gateway config.")
            pass
    # interface not found in ethernets and bonds means error
    else:
        print("Interface not found.")
        return "ERROR"

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
    parser.add_argument('--linkiface', dest='linkiface', help='Input your linked interface here. Mandatory.')
    parser.add_argument('--ipaddr', dest='ipaddr', help='Input your IP address here. Mandatory.')
    parser.add_argument('--ipprefix', dest='ipprefix', help='Input your IP prefix here. Mandatory.')
    parser.add_argument('--ipgateway', dest='ipgateway', help='Input your IP gateway here. Optional.')
    parser.add_argument('--filename', dest='filename', help='Input your file name to config here. Default uses file netplan-config.yaml in active folder.')

    args = parser.parse_args()

    linkiface = ""
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

    # 3 tham so linkiface, ipaddr, ipprefix phai co, neu ko thi ko chay
    try:
        linkiface = str(args.linkiface)
        ipaddr = str(args.ipaddr)
        ipprefix = str(args.ipprefix)    
    except Exception:
        print("Error occured. Require at least 3 parameters linkiface, ipaddr, ipprefix. Please rerun the command with proper parameters.")
        return 1
    
    # load cau hinh ip, tham so nay neu ko co cung duoc
    try:
        ipgateway = str(args.ipgateway)
    except Exception:
        pass
    
    # load config
    netplan_current_config = load_config(filename)
    if netplan_current_config == "ERROR":
        print("Error when loading network config.")
        return 1
    
    # config new interfaces
    netplan_new_config = place_config(netplan_current_config, linkiface, ipaddr, ipprefix, ipgateway)
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