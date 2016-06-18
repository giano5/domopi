#!/bin/bash

COLOR_BLUE='\033[34m'
COLOR_RED='\033[1;31m'
COLOR_RESET='\033[0m'
TITLE_COLOR='\033[1;39;46m'
CLOCK_COLOR='\033[1;39;44m'

# Indicare eventuale altro percorso
. domopi.functions

# Show running clock
#
#	ATTENZIONE! Eseguire prima di impostare TRAP segnali
function clock_start()
{
	while sleep 1;
	do
		tput sc
		tput cup 0 $(($(tput cols)-11))
		echo -e "$CLOCK_COLOR`date +%r`$COLOR_RESET"
		tput rc
	done &
	CLOCK_PID=$!
}

function clock_stop()
{
	( kill $CLOCK_PID ) >/dev/null 2>&1
}


trap cleanup EXIT

IDOWIRED="ID"
IDOWIRED_NEXT="WIREDPI"

DOMOPI_PRE_TRANSITION_CALLBACK=test_callback

#
# Funzione pulizia eventuali procedure e situazioni sospese
#
function cleanup()
{
	clock_stop
	clear
	return 0;
}

# Callback per esecuzione attuazione nuova configurazione di stato
#
#	$1 - Nuovo stato
#
function test_callback()
{
	echo execute callback
	#echo sensorID ${DOMOPI_sensorID[@]}
	#echo wiredpi ${DOMOPI_wiredpi[@]}
	for wirepi in ${DOMOPI_wiredpi[@]}
	do
		# rimuovere echo per eseguire
		echo gpio write $wiredpi $1
	done
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
		domopi_notice 'Opeazione conclusa con successo'
	else
		echo "Utilizzo file global.cfg esistente"
		echo
		echo -n "Identity: "
		domopi_ident
	fi
}


#
# Selezioni
#
function select_tipo()
{
	TIPO="false"
	while [ "$TIPO" = "false" ]
	do
		echo "Seleziona un tipo tra:"
		echo "  1 - LIGHT"
		echo "  2 - NOLIGHT"
		echo "  3 - SWITCH"
		echo "  4 - ALARM"
		echo "  5 - OTHER"
		echo "  6 - PULSE"
		echo -n "Scegli: "
		read
		case "$REPLY" in
		1) TIPO="LIGHT"	;;
		2) TIPO="NOLIGHT"	;;
		3) TIPO="SWITCH"	;;
		4) TIPO="ALARM"	;;
		5) TIPO="OTHER"	;;
		6) TIPO="PULSE"	;;
		*)
			;;
		esac
	done
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

		select_tipo

		echo -n "Patch number (lascare vuoto se non usato): "
		read PATCH
	
		echo -n "WiredPI number (lascare vuoto per automatico): "
		read WIRED

		domopi_timer_start create
		domopi_create -t "$TIPO" -p "$PATCH" -w "$WIRED" sensor "$DESC"
		domopi_time_elapsed create
	done
}

function create_mult()
{
	echo
	echo "Creazione sensori multipli:"

	echo -n "Nome del sensore (default=SENSOR): "
	read DESC

	select_tipo

	echo -n "Patch number (lascare vuoto se non usato): "
	read PATCH

	echo
	echo -n "Indicare quantità (default=10): "
	read COUNT
	echo -n "Genero sensori "
	domopi_timer_start create_mult
	for((i=1;i<=${COUNT:-10};i++))
	do
		domopi_create -t $TIPO -p "$PATCH" sensor "${DESC:-SENSOR}_$i" #>/dev/null 2>&1
		[ $? -eq 0 ] && echo -n . || echo -n '!'
	done
	echo
	domopi_time_elapsed create_mult
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
		echo -n "$IDOWIRED del sensore (scivere 'end' per terminare): "
		read ID
		[ -z "$ID" ] && continue
		[[ "$ID" = "end" ]] && break;
		echo -ne "Stato corrente del sensore $ID: $COLOR_BLUE"
		if [ $IDOWIRED = "ID" ]; then
			domopi_get_state -n $ID
		else
			domopi_get_state -w $ID
		fi
		echo -e $COLOR_RESET
		echo -n "Nuovo stato del sensore $ID (lasciare vuoto per non cambiare): "
		read STATE
		domopi_timer_start set_state
		if [ $IDOWIRED = "ID" ]; then
			[ -n "$STATE" ] && domopi_set_state -n $ID $STATE
			[ $? -ne 0 ] && echo Nessuna transizione di stato
		else
			[ -n "$STATE" ] && domopi_set_state -w $ID $STATE
			[ $? -ne 0 ] && echo Nessuna transizione di stato
		fi
		domopi_time_elapsed set_state
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
	echo -e "$TITLE_COLOR DOMOPI TEST PROGRAM                                                              $COLOR_RESET"
	tput sc
	tput cup 0 $(($(tput cols)-11))
	echo -e "$CLOCK_COLOR`date +%r`$COLOR_RESET"
	echo "--------------------------------------------------------------------------------"
	clock_start
}


#
#
#
function master_page()
{
	header
	echo '[1] - Inizializzazione e configurazioni'
	echo '[2] - Creazione sensore'
	echo "[3] - Modifica sensore"
	echo '[4] - Creazione gruppo'
	echo '[5] - Aggiungi sensore a gruppo'
	echo '[6] - Lista sensori'
	echo '[7] - Simulazione stati'
	echo '[8] - Rimozione sensore'
	echo '[9] - Lista wiredpi configurati'
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
	CURRENT_PAGE="modify_page $CURRENT_PAGE" 
}

function master_page_4()
{
	domopi_notice "NON ANCORA IMPLEMENTATO"
}

function master_page_5()
{
	domopi_notice "NON ANCORA IMPLEMENTATO"
}

function master_page_6()
{
	list
}

function master_page_7()
{
	state_simulation 
}

function master_page_8()
{

	DONE="false"
	while [ $DONE != "true" ]
	do
		echo -n "ID del sensore da rimuovere (scivere 'end' per terminare): "
		read ID
		[ -z "$ID" ] && continue
		[[ "$ID" = "end" ]] && break;
		domopi_destroy -n sensor $ID
	done
}

function master_page_9()
{
# TODO: Scegliere opzioni di selezioe per device (-d) o persensore (-s) o per tipo (-t)
	echo "Tutti i wired configurati:"
	domopi_get_wiredpi
	domopi_notice
}


function init_page()
{
	header
	echo '[1] - Rimuovi identità esistente'
	echo '[2] - Lista sensori'
	echo "[3] - Cambia riferimento in $IDOWIRED_NEXT (attuale: $IDOWIRED)"
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

function init_page_3()
{
	if [ $IDOWIRED = "ID" ]; then
		IDOWIRED="WIREDPI"
		IDOWIRED_NEXT="ID"
	else
		IDOWIRED="ID"
		IDOWIRED_NEXT="WIREDPI"
	fi
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


function modify_page()
{
	header
	echo '[1] - Cambia Patch'
	echo '[2] - Cambia Tempo massimo di esecuzione'
	echo '[3] - Cambia Stato iniziale'
	echo '[4] - Cambia descrizione'
	echo '[q] - Indietro'
}

function modify_page_1()
{
	DONE="false"
	while [ $DONE != "true" ]
	do
		echo -n "$IDOWIRED del sensore (scivere 'end' per terminare): "
		read ID
		[ -z "$ID" ] && continue
		[[ "$ID" = "end" ]] && break;
		if [ $IDOWIRED = "ID" ]; then
			PATCH=$( domopi_get_patch -s $ID )
		else
			PATCH=$( domopi_get_patch -w $ID )
		fi

		echo -n "Patch number (attuale $PATCH Lasciare vuoto per annullare modifiche): "
		read PATCH
		[ -z "$PATCH" ] && break;

		domopi_timer_start modify
		if [ $IDOWIRED = "ID" ]; then
			domopi_modify -s $ID patch $PATCH
		else
			domopi_modify -w $ID patch $PATCH
		fi
		domopi_time_elapsed modify
	done
}

function modify_page_2()
{
	#maxExecutionTime
	domopi_notice "NON ANCORA IMPLEMENTATO"
}

function modify_page_3()
{
	#defaultstate
	domopi_notice "NON ANCORA IMPLEMENTATO"
}

function modify_page_4()
{
	#descriptionU
	domopi_notice "NON ANCORA IMPLEMENTATO"
}



#
# MAIN PROGRAM ----------------------------------------
#

SHUTDOWN=false
CURRENT_PAGE=master_page
while ! $SHUTDOWN
do
	clock_stop
	${CURRENT_PAGE}
	echo
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
