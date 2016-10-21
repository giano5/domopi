#!/bin/bash
#
#
cat >/etc/default/domopi << EOT
# Global variables

DOMOPI_CONF_PATH=/usr/local/etc/domopi
DOMOPI_CONF_TEMPLATE_PATH=/usr/local/var/lib/domopi
DOMOPI_BIN_PATH=/usr/local/bin
DOMOPI_API_PATH=/usr/local/libexec
DOMOPI_PIPE_PATH=/usr/local/var/run/domopi.states
DOMOPI_PIPE=$DOMOPI_PIPE_PATH/domopi.states
# Deve essere un percorso scrivibile da utente esecutore 
DOMOPI_POWERON_PATH=/var/run/domopi
DOMOPI_POWERON_FILE=$DOMOPI_POWERON_PATH/poweron
EOT

. /etc/default/domopi

mkdir -p $DOMOPI_CONF_TEMPLATE_PATH $DOMOPI_BIN_PATH $DOMOPI_BIN_PATH $DOMOPI_API_PATH $DOMOPI_CONF_PATH

cp domopi.functions $DOMOPI_API_PATH
cp domod.sh $DOMOPI_BIN_PATH
cp modules.cfg $DOMOPI_CONF_TEMPLATE_PATH

. $DOMOPI_API_PATH/domopi.functions

if [ ! -f $DOMOPI_CONF_PATH/ident.cfg ]; then
	# Scegliere un nome
	domopi_init TESTBOX
fi

