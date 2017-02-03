#!/bin/bash
#
#

PURGE=false
[[ "$1" == "--purge" ]] && PURGE=true

USER=$(id -un)
if [ $USER != "root" ]
then
	echo Only root can uninstall
	exit 1
fi

if [ -f /usr/local/etc/default/domopi ] 
then
	. /usr/local/etc/default/domopi
	rm /usr/local/etc/default/domopi
elif [ -f /etc/default/domopi ] 
then
	. /etc/default/domopi
	rm /etc/default/domopi
else
	echo Domopi API seems not properly installed.
	echo No defaults found.
	exit 2
fi


[ -d /usr/local/etc/default ] && rmdir /usr/local/etc/default

rm $DOMOPI_API_PATH/domopi.functions
rm $DOMOPI_BIN_PATH/domod.sh
rm -f $DOMOPI_CONF_TEMPLATE_PATH/modules.cfg* 
if $PURGE 
then
	rm -f $DOMOPI_CONF_PATH/*
	rmdir $DOMOPI_CONF_PATH 
else
	echo Configurations in $DOMOPI_CONF_PATH not removed.
	echo Use --purge for remove it.
fi
rm -f $DOMOPI_PIPE
rm -f $DOMOPI_POWERON_FILE

rmdir $DOMOPI_CONF_TEMPLATE_PATH $DOMOPI_POWERON_PATH 2>/dev/null

