#!/bin/bash

# Indicare eventuale altro percorso
. domopi.functions


COLOR_BLUE='\033[34m'
COLOR_RESET='\033[0m'

function notice()
{
	echo
	echo $@
	echo 'Premi invio per proseguire'
	read
}


function init()
{
	if [ ! -f global.cfg ]
	then
		echo "DOMOPI - Inizializzazione -------------------"
		echo
		echo "ATTENZIONE! Sovrascrive configurazione esistente"
		echo -n "Inserire un nome per l'unità: "
		read NAME

# Fase inizializzazione dispositivo
#
#	Crea i file di configurazione nel percorso definito nella
#	libreria:
#		ident.cfg	Identifica l'hardware
#		global.cfg	Configurazione da manipolare
#
#
		domopi_init "$NAME"
		notice 'Opeazione conclusa con successo'
	else
		echo "Utilizzo file global.cfg esistente"
		echo
		echo -n "Identity: "
		domopi_ident
		CURRENT_PAGE="second_page $CURRENT_PAGE" 
	fi
}


#
# Creazione sensori
#
# Opeazione effettuata con:
#
#	domopi_create <tipo oggetto> <descrizione>
#
#	dove il <tipo oggetto> è "sensor"
#
function create()
{
	echo
	echo "Creazione sensore:"

	DONE="false"
	while [ $DONE != "true" ]
	do
		echo -n "Nome del sensore (scrivere 'end' per terminare): "
		read DESC
		[[ "$DESC" = "end" ]] && break;

		echo -n "IN/OUT (digitare 'i' oppure 'o')? "
		read VERSO
		echo -n "Patch number: "
		read PATCH
	
		domopi_create -$VERSO "$PATCH" sensor "$DESC"
	done
}


#
# Lista sensori (ID e descrizione)
#
function list()
{
	echo
	echo Sensori configurari:
	echo
	domopi_list sensor
	notice
}


#
# Simulazione cambi di stato
#
#	Un programma ha bisogno di invocare solo:
#
#	domopi_set_state <ID sensore> <stato>
#	domopi_get_state <ID sensore>
#
function state_simulation()
{
	echo
	echo 'Simulazione (leggere e scrivere stati sui sensori)'
	echo
	DONE="false"
	while [ $DONE != "true" ]
	do
		echo 'Lettura stato'
		echo -n "ID del sensore (scivere 'end' per terminare): "
		read ID
		[ -z "$ID" ] && continue
		[[ "$ID" = "end" ]] && break;
		echo -ne "Stato corrente del sensore $ID: $COLOR_BLUE"
		domopi_get_state -q -n $ID
		echo -e $COLOR_RESET
		echo -n "Nuovo stato del sensore $ID (lasciare vuoto per non cambiare): "
		read STATE
		[ -n "$STATE" ] && domopi_set_state -n $ID $STATE
		[ $? -ne 0 ] && echo Nessuna transizione di stato
		echo
		echo Condizione generale del sistema
		list
		echo
	done
}


#
#
#
function master_page()
{
	clear
	echo 'DOMOPI TEST PROGRAM'
	echo '----------------------------'
	echo '[1] - Inizializzazione'
	echo '[2] - Creazione sensore'
	echo '[3] - Lista sensori'
	echo '[4] - Simulazione stati'
	echo '[q] - Quit'
}

function second_page()
{
	echo
	echo '[1] - Rimuovi identità esistente'
	echo '[3] - Lista sensori'
	echo '[q] - Indietro'
}

# MAIN PROGRAM -------------

SHUTDOWN=false
CURRENT_PAGE=master_page
while ! $SHUTDOWN
do
	$CURRENT_PAGE
	echo -ne "Seleziona una funzione: "
	read
	case "$REPLY" in
	1)	if [[ "$CURRENT_PAGE" = "master_page" ]]; then	
			init
		else
			rm -f ident.cfg global.cfg	
			read POP CURRENT_PAGE <<< "$CURRENT_PAGE"
		fi
				;;
	2)	create	;;
	3)	list	;;
	4)	state_simulation ;;
	q)	# Ritorno a pagina superiore o temine
		read POP CURRENT_PAGE <<< "$CURRENT_PAGE"
		[ -z "$CURRENT_PAGE" ] && SHUTDOWN=true;;
	*)
		;;
	esac
done

echo Bye
