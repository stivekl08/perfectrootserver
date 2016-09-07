#!/bin/bash
# The perfect rootserver
# by Zypr
# https://github.com/zypr/perfectrootserver
# Big thanks to https://github.com/andryyy/mailcow
# Compatible with Debian 8.x (jessie)

source sources/script/functions.sh

source sources/script/AddNewSite.sh
source sources/script/ajenti.sh
#source sources/script/openvpn.sh
source sources/script/ts3.sh
source sources/script/vsftpd.sh
source sources/script/DisableRootLogin.sh


checksystem
checkconfig
installation
addoninformation

addnewsite
ajenti
#openvpn
ts3
vsftpd
DisableRootLogin.sh

logininformation
instructions
