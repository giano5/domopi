#!/bin/bash
DEBUG=true

trap process_USR1 SIGUSR1
trap process_TERM SIGTERM

# Rilegge la configurazione ?
process_USR1() {
	return 0
}

process_TERM() {
	rm $PIDFILE_BASEPATH/domod-$mode.pid
	exit 0
}


BASE_PATH="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROGRAM=$(basename $0)
PIDFILE_BASEPATH=/var/run/domopi/
cd /


# Esecuzione come figlio
if [ "$1" = "child" ] ; then
    shift; tty="$1"; shift
    umask 0
    $BASE_PATH/$PROGRAM refork "$tty" "$@" </dev/null >/dev/null 2>/dev/null &
    exit 0
fi

# Esecuzione padre (prima esecuzione)
if [ "$1" != "refork" ] ; then
    tty=$(tty)
    setsid $BASE_PATH/$PROGRAM child "$tty" select "$@" &
    setsid $BASE_PATH/$PROGRAM child "$tty" fetch "$@" &
    exit 0
fi

# Refork avvenuto
exec >/dev/null
exec 2>/dev/null
exec 0</dev/null

shift; tty="$1"; shift
mode=$1; shift


#
#	TODO: gestire opzioni
#
#	-f il file di configurazione
#	-L libreria domopi
#
DOMOPI_INSTALLATION_PATH=/home/andrea/repo/domopi/src
source $DOMOPI_INSTALLATION_PATH/domopi.functions

DOMOPI_PRE_TRANSITION_CALLBACK=run_callback
DOMOPI_GROUP_PRE_TRANSITION_CALLBACK=group_callback
DOMOPI_POLL_CALLBACK=poll_callback

# Callback per esecuzione attuazione nuova configurazione di stato
#
#	$1 - Nuovo stato
#
#	SOLO SE OPERAZIONE SU DEVICE LOCALE
#
function run_callback()
{
	echo execute callback
	#echo sensorID ${DOMOPI_sensorID[@]}
	#echo wiredpi ${DOMOPI_wiredpi[@]}

	for index in ${!DOMOPI_wiredpi[@]}
	do
		# NOTA: rimuovere echo per eseguire
		[ "$UUID" = "${DOMOPI_device[$index]}" ] && 
			echo gpio write ${DOMOPI_wiredpi[$index]} $1
	done
}

# Esempio
function group_callback()
{
	# echo execute callback for group $@
	return 0
}


#	SOLO SE OPERAZIONE SU DEVICE LOCALE
# Esempio
function poll_callback()
{
	newState=0
	if [ -n "$1" ]; then
		# NOTA: commentare o rimuovere per rendere operativo
		[ -f /tmp/gpio_test_state ] && read newState < /tmp/gpio_test_state
		# NOTA: rimuovere commento per rendere operativo
		#newState=$( gpio read $1 )
	fi
	return $newState
}



# Genera file di pid
[ -d $PIDFILE_BASEPATH ] && echo $$ >$PIDFILE_BASEPATH/domod-$mode.pid

# tty è il terminale da cui è stato lanciato
#	potrebbe non esistere più
#
# main loop

case $mode in
select)
	while true; do
		domopi_select
		#sleep 1	# Troppo ritardo ?
		usleep 500000	# Numero pid utilizzati aumenta in modo elevato
	done
	;;

fetch)
	while true; do
		domopi_fetch
   		sleep 1
	done
	;;
esac

# Non viene raggiunto mai questo punto
exit 

