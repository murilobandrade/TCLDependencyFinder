#!/usr/bin/tclsh
oo::class create File {
	constructor {name} {
		my variable desName
		my variable txtContent
		my variable lstSource
		my variable sctContent
		
		set desName $name
		puts $desName
		set sctContent [my openFile]
	}

	#TODO: Montar uma expressão regular, lendo o codigo-fonte,
	# Buscando pelos comandos 'source' e 'package require'
	#TODO: Contemplar o caracter '\' na regexp
	#TODO: Considerar que um programa pode ser escrito em uma linha com os comandos separados por ';'
	method matchSource {str content} {
		set reg {^}
		foreach word $str {
			append reg {[[:blank:]]*} $word { }
		}
		puts $reg
		return [regexp $reg $content]
	}
	unexport matchSource

	#TODO: annotation/definition to private class, for dont forget to change 'method name' and 'unexport name' 
	method openFile {} {
		my variable desName
		if ![file exists $desName] {
			throw {FILE DONTEXISTS {file dont exists}} {O arquivo não existe}
		}
		if ![file isfile $desName] {
			throw {FILE ISNTFILE {file isnt file}} {O arquivo não é um arquivo}
		}
		if ![file readable $desName] {
			throw {FILE ISNTREAD {file isnt readable}} {O arquivo não está liberado para leitura}
		}
		set s [open $desName r]
		return $s
	}
	unexport openFile
	
	
	method readLine {{line ""}} {
		my variable sctContent
		if {[gets $sctContent l] < 0} {
			throw {FILE EOF {file is on end}} {O arquivo chegou no fim}
		} elseif {[string index $l end] == "\\"} {
			set l [string range $l 0 [expr [string length $l] -2]]
			set line [string cat $line [my readLine $l]]
		} else {
			set line [string cat $line $l]
		}

		return $line
	}
	unexport readLine
	
	method findPackage {} {
		puts [my matchSource "package require" [my readLine]]
	}
}

#set objPrincipal [File new "nome do arquivo.tcl"]

#TODO: Contemplar a situação de um arquivo "a", carregar um "b" e o "b" carregar um "a"