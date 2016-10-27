
# Tell Tcl that we are a package
package provide icblockade 1.0

namespace eval ::ICBK:: {
	namespace export bdtoolkit
}

# Source procs that are common between GUI and Command Line modes
if {[catch {source [file join $env(ICBKDIR) icbk_procs.tcl]}]} {
	puts "Fatal error! Could not load icbk_procs.tcl"
	return 1;
}


# If there is Tk and Tile -> start GUI
if { [info exists tk_version] } {
	package require Tk 8.5
	package require tile

	# Start GUI
	if {[catch {source [file join $env(ICBKDIR) icbk_gui.tcl]}]} {
		puts "Fatal error! Could not load icbk_gui.tcl"
		return 1;
	}

}

# Proc that gets called by VMD
proc icbk { } {
	return [eval ::ICBK::gui::icbk_gui]
}


