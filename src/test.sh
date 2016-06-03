#!/bin/bash

# Indicare eventuale altro percorso
. domopi.functions


COLOR_BLUE='\033[34m'
COLOR_RED='\033[1;31m'
COLOR_RESET='\033[0m'


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
		domopi_notice 'Opeazione conclusa con successo'
	else
		echo "Utilizzo file global.cfg esistente"
		echo
		echo -n "Identity: "
		domopi_ident
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
	
		domopi_timer_start create
		domopi_create -$VERSO "$PATCH" sensor "$DESC"
		domopi_time_elapsed create
	done
}

function create_mult()
{
	echo
	echo "Creazione sensori multipli:"

	echo -n "Nome del sensore (default=SENSOR): "
	read DESC

	echo -n "Patch number: "
	read PATCH
	echo -n "IN/OUT (digitare 'i' oppure 'o' )? "
	read VERSO

	echo
	echo -n "Indicare quantità (default=10): "
	read COUNT
	echo -n "Genero sensori "
	for((i=1;i<=${COUNT:-10};i++))
	do
		domopi_create -${VERSO:-o} "$PATCH" sensor "${DESC:-SENSOR}_$i" 2>/dev/null
		[ $? -eq 0 ] && echo -n . || echo -n '!'
	done
	echo
	domopi_notice 'Opeazione conclusa con successo'
}


#
# Lista sensori (ID e descrizione)
#
function list()
{
	echo
	echo Sensori configurari:
	echo
	domopi_list sensor | more
	domopi_notice
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
		domopi_timer_start set_state
		[ -n "$STATE" ] && domopi_set_state -n $ID $STATE
		domopi_time_elapsed set_state
		[ $? -ne 0 ] && echo Nessuna transizione di stato
		echo
		echo Condizione generale del sistema
		list
		echo
	done
}


#-----------------------------------------------------------
# Gestion pagine
#
#	Ogni funzione <nome> rappresenta il menu
#	Ogni funzione <nome>_<op> rappresenta operazione
#
#	La variabile CURRENT_PAGE contiene la pila navigazione
#	pagine con il nome della pagina corrente in testa
#
#	Nel caso di pagine intermedie la funzione di operazione
#	implementa il cambio pagina introducendo il nome della
#	sottopagina (es CURRENT_PAGE="create_page $CURRENT_PAGE" )
#
function header()
{
	clear
	echo 'DOMOPI TEST PROGRAM'
	echo '----------------------------'
}


#
#
#
function master_page()
{
	header
	echo '[1] - Inizializzazione'
	echo '[2] - Creazione sensore'
	echo '[3] - Lista sensori'
	echo '[4] - Simulazione stati'
	echo '[q] - Quit'
}

function master_page_1()
{
	init
	CURRENT_PAGE="init_page $CURRENT_PAGE" 
}

function master_page_2()
{
	CURRENT_PAGE="create_page $CURRENT_PAGE" 
}

function master_page_3()
{
	list
}

function master_page_4()
{
	state_simulation 
}

function init_page()
{
	header
	echo '[1] - Rimuovi identità esistente'
	echo '[2] - Lista sensori'
	echo '[q] - Indietro'
}

function init_page_1()
{
	rm -f ident.cfg global.cfg	
	read POP CURRENT_PAGE <<< "$CURRENT_PAGE"
}

function init_page_2()
{
	list
}

function create_page()
{
	header
	echo '[1] - Crea oggetti liberamente'
	echo '[2] - Crea serie di oggetti'
	echo '[q] - Indietro'
}


function create_page_1()
{
	create
}

function create_page_2()
{
	create_mult
}


#
# MAIN PROGRAM ----------------------------------------
#

SHUTDOWN=false
CURRENT_PAGE=master_page
while ! $SHUTDOWN
do
	${CURRENT_PAGE}
	echo -ne "Seleziona una funzione: "
	read OP
	[ -z "$OP" ] && continue
	if [ $OP = "q" ]; then
		# Ritorno a pagina superiore o temine
		read POP CURRENT_PAGE <<< "$CURRENT_PAGE"
		[ -z "$CURRENT_PAGE" ] && SHUTDOWN=true
		continue
	fi
	read POP REST <<< "$CURRENT_PAGE"
 	if declare -F | grep -q ${POP}_$OP ; then	
		${POP}_$OP
	else
		echo -e "${COLOR_RED}NON IMPLEMENTATO${COLOR_RESET}"
	fi

done

echo Bye
