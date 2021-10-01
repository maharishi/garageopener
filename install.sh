#!/bin/sh

ln -fs /root/gopener.service /etc/init.d/gopener.service 
ln -fs /root/garageopener /etc/config/garageopener 
chmod 744 /etc/init.d/gopener.service
chmod 744 /root/garageopener.sh
/etc/init.d/gopener.service enable
/etc/init.d/gopener.service start
