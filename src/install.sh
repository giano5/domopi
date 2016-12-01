#!/bin/bash
#
#

USER=$(id -un)
if [ $USER != "root" ]
then
	echo Only root can install
	exit 1
fi

if [ -z "$1" ] 
then
	echo -n "Domod daemon run as user [$USER]: "
	read RUN_AS_USER
else
	RUN_AS_USER=$1
fi
[ -z "$RUN_AS_USER" ] && RUN_AS_USER=$USER

mkdir -p /usr/local/etc/default
cat >/usr/local/etc/default/domopi << EOT
# Global variables

DOMOPI_USER=$RUN_AS_USER
DOMOPI_CONF_PATH=/usr/local/etc/domopi
DOMOPI_CONF_TEMPLATE_PATH=/usr/local/var/lib/domopi
DOMOPI_BIN_PATH=/usr/local/bin
DOMOPI_API_PATH=/usr/local/libexec
DOMOPI_PIPE_PATH=/usr/local/var/run
DOMOPI_PIPE=\$DOMOPI_PIPE_PATH/domopi.states
# Deve essere un percorso scrivibile da utente esecutore 
DOMOPI_POWERON_PATH=/var/run/domopi
DOMOPI_POWERON_FILE=\$DOMOPI_POWERON_PATH/poweron
EOT

. /usr/local/etc/default/domopi

mkdir -p $DOMOPI_CONF_TEMPLATE_PATH $DOMOPI_BIN_PATH $DOMOPI_BIN_PATH $DOMOPI_API_PATH $DOMOPI_CONF_PATH $DOMOPI_POWERON_PATH 

# Trattiamo come una cartella tmp in attesa di definire utenti e gruppi
# che possano condividere questo medesimo spazio
if [ ! -d $DOMOPI_PIPE_PATH ]; then
	mkdir -p $DOMOPI_PIPE_PATH
	chmod ugo+trwx $DOMOPI_PIPE_PATH
else
	echo
	echo "WARNING: $DOMOPI_PIPE_PATH exists!!!"
	echo Check write permission for user $RUN_AS_USER.
fi

chown $DOMOPI_USER $DOMOPI_CONF_PATH $DOMOPI_POWERON_PATH

install --mode 555 domopi.functions $DOMOPI_API_PATH
install --mode 555 domod.sh $DOMOPI_BIN_PATH
if [ ! -f $DOMOPI_CONF_TEMPLATE_PATH/modules.cfg ]; then
	if [ ! -f modules.cfg ] ; then
		echo
		echo "ERROR: Missing hardware configuration template."
		echo "Please use "
		echo 
		echo ". domopi.functions"
		echo "domopi_install"
		echo
		echo "for generate modules.cfg in current directory."
		exit 1
	else
		install --mode 444 modules.cfg $DOMOPI_CONF_TEMPLATE_PATH
	fi
fi



#
#	Dummy configuration (for experimental environment)
#
if [ ! -f $DOMOPI_CONF_PATH/ident.cfg ]; then
	# Scegliere un nome
	su - $RUN_AS_USER -c '. /usr/local/etc/default/domopi ; . $DOMOPI_API_PATH/domopi.functions; domopi_init TESTBOX'
fi

