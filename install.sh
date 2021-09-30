#!/bin/sh

ln -fs /root/garageopener.service /etc/init.d/garageopener.service 
ln -fs /root/garageopener /etc/config/garageopener 
chmod 744 /etc/init.d/garageopener.service
chmod 744 /root/garageopener.sh
/etc/init.d/garageopener.service enable
/etc/init.d/garageopener.service start
