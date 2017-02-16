#!/bin/bash
#
#	Utility per eseguire via php funzioni librerie bash
#	attraverso una semplice system() come segue:
#
#	<?php
#
#	system('php_wrapper.sh domopi_show_hardware', $output);
#
#	// NOTA: Risposta in un array: un elemento per linea
#	
#	var_dump($output);
#	?>
#
#	@author Andrea Tassotti
#
#


[ -f /usr/local/etc/default/domopi ] && . /usr/local/etc/default/domopi
[ -f /etc/default/domopi ] && . /etc/default/domopi

source $DOMOPI_API_PATH/domopi.functions

command=$1
shift
$command "$@"
