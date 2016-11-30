#!/bin/bash
#
#    This program is free software: you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation, either version 3 of the License, or
#    (at your option) any later version.
#
#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.
#
#    You should have received a copy of the GNU General Public License
#    along with this program.  If not, see <http://www.gnu.org/licenses/>.
#
#    Copyrights (C) 2016 
#
#	 @author: Andrea Tassotti
#
DEBUG=true
SHUTDOWN=false

trap process_USR1 SIGUSR1
trap process_TERM SIGTERM
trap process_PIPE SIGPIPE

# Rilegge la configurazione ?
process_USR1() {
	return 0
}

process_TERM() {
	# ATTENZIONE! SIGPIPE implica anche SIGTERM
	# Usiamo variabile SHUTDOWN per evitare loop tra segnali
	! $SHUTDOWN && kill -s SIGPIPE $(cat $PIDFILE_BASEPATH/domod.pid)
	[ -n "$CHILDPID" ] && kill $CHILDPID
	rm $PIDFILE_BASEPATH/domod.pid
	exit 0
}

process_PIPE() {
	SHUTDOWN=true
	return 0
}


# Canonical name
BASE_PATH=$( cd $( dirname "${BASH_SOURCE[0]}" ) && pwd )
PROGRAM=$(basename $0)
PIDFILE_BASEPATH=/var/run/domopi/
cd /

if [[ "$1" = "kill" ]] 
then
	if [ -f $PIDFILE_BASEPATH/domod.pid ] ; then
		kill -s SIGTERM $(cat $PIDFILE_BASEPATH/domod.pid) >/dev/null 2>&1 ||
			rm $PIDFILE_BASEPATH/domod.pid
	fi
	exit 0
fi

if [[ "$1" = "status" ]] 
then
	PIDS=$(pidof -x "$PROGRAM")
	PIDS=$(echo $PIDS | sed -e "s/$$//" )
	MESSAGE=
	ret=0

	if [ -f $PIDFILE_BASEPATH/domod.pid ] 
	then
		STATE=active
		PIDCOUNT=$( echo $PIDS| wc -w )
		if [ $PIDCOUNT -eq 0 ]; then
			STATE=dead
			MESSAGE="Pidfile still exists"
			ret=3
		elif [ $PIDCOUNT -ne 2 ]; then
			ret=2
			if echo $PIDS | grep -q $(cat $PIDFILE_BASEPATH/domod.pid) ; then
				STATE=degraded
				MESSAGE="Main thread still alive (block in a pipe)"
			else
				STATE=degraded
				MESSAGE="Secondary thread still alive"
			fi
		fi
	else
		STATE=dead
		ret=0
	fi

	echo -n "Service $STATE"
	[ -n "$PIDS" ] && echo " ($PIDS)" || echo
	[ -n "$MESSAGE" ] && echo $MESSAGE
 	exit $ret
fi

# Esecuzione come figlio
if [ "$1" = "child" ] ; then
    shift
    umask 0
    $BASE_PATH/$PROGRAM refork "$@" </dev/null >/dev/null 2>/dev/null &
    exit 0
fi

# Esecuzione padre (prima esecuzione)
if [ "$1" != "refork" ] ; then
    setsid $BASE_PATH/$PROGRAM child "$@" &
    exit 0
fi

# Refork avvenuto
exec >/dev/null
exec 2>/dev/null
exec 0</dev/null

shift

#
#	TODO: gestire opzioni
#
#	-p path configurazione (DOMOPI_CONF_PATH)
#	-m il file dei moduli (DOMOPI_CONF_TEMPLATE_PATH)
#	-L libreria domopi (DOMOPI_API_PATH)
#	Queste devono eseguire overriding configurazione
#	default cablata in domopi.functions
#
[ -f /usr/local/etc/default/domopi ] && . /usr/local/etc/default/domopi
[ -f /etc/default/domopi ] && . /etc/default/domopi

source $DOMOPI_API_PATH/domopi.functions

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
	#echo sensorID ${DOMOPI_sensorID[@]}
	#echo wiredpi ${DOMOPI_wiredpi[@]}

	for index in ${!DOMOPI_wiredpi[@]}
	do
		# NOTA: rimuovere echo per eseguire
		[ "$UUID" = "${DOMOPI_device[$index]}" ] && 
			! $DEBUG && gpio write ${DOMOPI_wiredpi[$index]} $1
	done
}

# 
function group_callback()
{
	# echo execute callback for group $@
	return 0
}


#	AGISCE SOLO SU DEVICE LOCALE
function poll_callback()
{
	newState=0
	if [ -n "$1" ] && ! $DEBUG; then
		newState=$( gpio read $1 )
	fi
	return $newState
}



# Genera file di pid
[ -d $PIDFILE_BASEPATH ] && echo $$ >$PIDFILE_BASEPATH/domod.pid


# Thread 1: In realtà child
(
	while true; do
		domopi_select
		#sleep 1	# Troppo ritardo ?
		usleep 500000	# Numero pid utilizzati aumenta in modo elevato
	done
) &
CHILDPID=$!

# Thread 0 (Main)
#
#	Il metodo domopi_fetch è bloccante in quanto
#	è sincronizzato su semaforo di una named pipe.	
#	Non serve quindi temporizzazione per diminuire
#	consumo CPU.
#
#	il thread principale si chiude se si chiude il thread 1, ma solo se 
#	viene attivato dalla pipe che deve contenere un dato o chiudersi
#	Questo consente la terminazione del demone che potrà
#	essere riavviato da systemd
#
while ! SHUTDOWN && [ $(jobs -p ) = "$CHILDPID" ]; do
	domopi_fetch
done

# Non viene raggiunto mai questo punto
exit 

