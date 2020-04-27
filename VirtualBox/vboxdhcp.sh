#!/usr/bin/env bash

echo "Remember to first configure vboxnet0 to 10.30.30.17/28 or Press CTRL+C now!"
sleep 10

VBoxManage dhcpserver modify --network=HostInterfaceNetworking-vboxnet0 --server-ip=10.30.30.17 --lower-ip=10.30.30.18 --upper-ip=10.30.30.30 --netmask=255.255.255.240
#VBoxManage dhcpserver modify --network=HostInterfaceNetworking-vboxnet1 --server-ip=10.30.30.33 --lower-ip=10.30.30.34 --upper-ip=10.30.30.46 --netmask=255.255.255.240
#VBoxManage dhcpserver modify --network=HostInterfaceNetworking-vboxnet2 --server-ip=10.30.30.49 --lower-ip=10.30.30.50 --upper-ip=10.30.30.62 --netmask=255.255.255.240
#VBoxManage dhcpserver modify --network=HostInterfaceNetworking-vboxnet3 --server-ip=10.30.30.65 --lower-ip=10.30.30.66 --upper-ip=10.30.30.78 --netmask=255.255.255.240
