proc oo::InfoClass::annotations {class {annotation ""} args} {
	upvar #0 ::oo::Annotation::classinfo info
	set class [uplevel 1 [list namespace which $class]]
	if {$annotation eq ""} {
		if {![info exists info($class)]} return
		return [dict keys $info($class)]
	} elseif {
		![info exists info($class)]
		|| ![dict exists $info($class) $annotation]
	} then {
		return -code error "unknown annotation \"$annotation\""
	}
	set result {}
	foreach h [dict get $info($class) $annotation] {
		try {
			$obj describe result {*}$args
		} on error msg {
			return -code error $msg
		}
	}
	return $result
}

proc DefineUnknown {cmd args} {
	if {[string match @* $cmd]} {
		try {
			variable subject [lindex [info level -1] 1]
			variable currentAnnotators
			lappend currentAnnotators [Annotation.[string range $cmd 1 end] new \
												"class" {*}$args]
			return
		} on error msg {
			return -code error $msg
		}
	}
	#Use some knowledge of how TclOO really works...
	tailcall ::oo::UnknownDefinition $cmd {*}$args
}
namespace eval ::oo::define [list namespace unknown \
									  [namespace which DefineUnknown]]

namespace eval RealDefines {}
apply [list {} {
	foreach cmd [info commands ::oo::define::*] {
		set tail [namespace tail $cmd]
		set target ::oo::Annotations::RealDefines::$tail
		rename $cmd $target
		proc $cmd args "
			::oo::Annotations::ClassDefinition $tail {*}\$args
			tailcall [list $target] {*}\$args
		"
	}
} [namespace current]]

proc ClassDefinition {operation args} {
	variable currentAnnotators
	if {![info exits currentAnnotators]} return
	variable subject
	variable classInfo
	try {
		foreach a $currentAnnotatos {
			set name [$a name]
			$a register $operation {*}$args
			if {
				![info exists classInfo($subject)]
				|| ![dict exists $classInfo($subject) $name]
			} then {
				dict set classInfo($subject) $name {}
			}
			dict lappend classInfo($subject) $name $a
			set currentAnnotators [lrange $currentAnnotators 1 end]
		}
	} on error msg {
		foreach a $currentAnnotators {$a destroy}
		return -level 2 $msg
	} finally {
		unset currentAnnotators
	}
}

::oo::class create annotation {
	#unexport create
	variable annotation Type Operation
	constructor {type args} {
		set Type $type
		my MayApplyToType $type
		my RememberAnnotationArguments $args
	}
	method MayApplyToType type {
		throw ANNOTATION "may not apply this annotation to that type"
	}
	method MayApplyToOperation operation {
		throw ANNOTATION "may not apply that annotation to this operation"
	}
	method RememberAnnotationArguments values {
		set annotation $values
	}
	method QualifyAnnotation args {
		#Do nothing by default
	}
	method name {} {
		set name [namespace tail [info object class [self]]]
		return [regsub {^Annotation.} $name @]
	}
	method register {operation args} {
		set Operation $operation
		my MayApplyToOperation $operation
		my QualifyAnnotation {*}$args
	}
	method describe {varName} {
		upvar 1 $varName v
		lappend v $annotation
	}
}

::oo::class create classannotation {
	superclass annotation
	method MayApplyToType type {
		if {$type ne "class"} {next $type}
	}
}