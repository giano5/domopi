#!/bin/bash

# Indicare eventuale altro percorso
. domopi.functions


echo "DOMOPI - Inizializzazione -------------------"
echo
echo "ATTENZIONE! Cancella configurazione esistente"
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


#
# Creazione sensori
#
# Opeazione effettuata con:
#
#	domopi_create <tipo oggetto> <descrizione>
#
#	dove il <tipo oggetto> è "sensor"
#
echo
echo "Creazione sensori:"

DONE="false"
while [ $DONE != "true" ]
do

	echo -n "Nome del sensore (scivere 'end' per terminare): "
	read DESC
	[[ "$DESC" = "end" ]] && break;
	
	domopi_create sensor "$DESC"
done


#
# Lista sensori (ID e descrizione)
#
echo
echo Sensori configurari:
echo -e "ID\tDescription"
domopi_list sensor


#
# Simulazione cambi di stato
#
#	Un programma ha bisogno di invocare solo:
#
#	domopi_set_state <ID sensore> <stato>
#	domopi_get_state <ID sensore>
#
echo
echo Simulazione
echo
DONE="false"
while [ $DONE != "true" ]
do
	echo -n "ID del sensore (scivere 'end' per terminare): "
	read ID
	[[ "$ID" = "end" ]] && break;
	echo -n "Stato corrente del sensore $ID: "
	domopi_get_state $ID
	echo -n "Nuovo stato del sensore $ID (lasciare vuoto per non cambiare): "
	read STATE
	[ -n "$STATE" ] && domopi_set_state $ID $STATE
done
