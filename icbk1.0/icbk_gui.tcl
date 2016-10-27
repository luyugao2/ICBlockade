#
namespace eval ::ICBK::gui {
    variable window     ".icbk_main_window" ; # Main window
}

proc ::ICBK::gui::icbk_gui {} {
    variable window

    ::ICBK::newProject

    # If windows has already been initialized, just bring it up
    if { [winfo exists $window] } {
        wm deiconify $window
        return
    }

    ### Destroy the window if it exists
    catch {destroy $window}
    toplevel $window

    grid columnconfigure $window 0 -weight 1
    grid rowconfigure    $window 0 -weight 1

    wm title      $window "Pore Explorer"    ; # window title
    wm resizable  $window 0 0                ; # make window resizable
#    wm geometry   $window 640x480
#    wm minsize    $window 700 520            ; # minimum window size
#    wm maxsize    $window 700 520            ; # maximum window size

    
    ### Menubar
    menu $window.menubar -tearoff 0
    $window configure -menu $window.menubar

    set menu $window.menubar
    menu $menu.file    -tearoff 0
    menu $menu.options -tearoff 0
    menu $menu.apple   -tearoff 0
    menu $menu.help    -tearoff 0

    $menu add cascade -menu $menu.file    -label "Pore Explorer"
    $menu add cascade -menu $menu.options -label "Options"
    $menu add cascade -menu $menu.help    -label "Help"

    $menu.file add command -label "New project"          -command { ::ICBK::unloadMolecules; ::ICBK::newProject; }
    $menu.file add command -label "Load project..."      -command { ::ICBK::unloadMolecules; ::ICBK::newProject; ::ICBK::gui::loadProject; }
    $menu.file add separator
    $menu.file add command -label "Save current project" -command { ::ICBK::gui::saveProject $::ICBK::statefilename }
    $menu.file add command -label "Save project as..."   -command   ::ICBK::gui::saveProject
    $menu.file add separator
    $menu.file add command -label "Close project"          -command { ::ICBK::unloadMolecules; ::ICBK::newProject; }

    # Put 'Preferences' menu item in the right place
    if {![string eq "Darwin" $::tcl_platform(os)]} {
        $menu.file add separator
        $menu.file add command -label "Preferences..."      -command  ::ICBK::gui::showPref -font TkMenuFont; # have to catch{exit} since otherwise it produces an error

    } else {
        ### OS X specific
        #set ::tk::mac::useThemedToplevel true
        $menu add cascade -menu $menu.apple;    ### apple & help menus.
        # proc ::tk::mac::ShowPreferences {} { }; ### Preferences - do nothing for now
    }

    $menu.file add separator
    $menu.file add command -label "Close window"    -command { wm withdraw $::ICBK::gui::window; }
    $menu.file add command -label "Quit"            -command { ::ICBK::unloadMolecules; wm withdraw $::ICBK::gui::window; }

    #$menu.file add separator
    #$menu.file add command -label "Quit VMD"        -command  { catch {exit} } ; # have to catch{exit} since otherwise it produces an error

    $menu.options add checkbutton -label "Show advanced settings" -variable ::ICBK::gui::showadvanced
    ### END of menubar

    ###
    # MAIN frame holding notebook top menu (tabs), (soon) log-console

    ttk::frame $window.hlf
    grid $window.hlf  -column 0 -row 0 -sticky nsew
    grid columnconfigure $window.hlf 0 -weight 1
    grid    rowconfigure $window.hlf {0 1} -weight 1

    ### Notebook
    ttk::notebook $window.hlf.nb
    grid $window.hlf.nb -column 0 -row 0 -sticky nsew

    ### Configure resizability
    grid columnconfigure $window.hlf.nb 0 -weight 1
    grid rowconfigure    $window.hlf.nb 1 -weight 0
    grid rowconfigure    $window.hlf.nb 1 -weight 1

    $window.hlf.nb add [ttk::frame $window.hlf.nb.tab1] -text "something"
    #$window.hlf.nb add [ttk::frame $window.hlf.nb.tab2] -text "Geometry"
    $window.hlf.nb add [ttk::frame $window.hlf.nb.tab3] -text "Biomolecules"
    $window.hlf.nb add [ttk::frame $window.hlf.nb.tab4] -text "BD particles"
#    $window.hlf.nb add [ttk::frame $window.hlf.nb.tab5] -text "Potentials"
    $window.hlf.nb add [ttk::frame $window.hlf.nb.tab6] -text "BD model" 
    ttk::notebook::enableTraversal $window.hlf.nb

    # Loop over all tabs and assign variables for easy access (tab1, tab2, ...)
    # Configure the 0-th column of all tabs with weight "1"
    foreach kid [winfo children $window.hlf.nb] {
        set name [string range [file extension $kid] 1 end]; # name = tab1, tab2, ...
        set [set name] $kid;                                 # set tab1 $window.hlf.nb.tab1
        grid columnconfigure $kid 0 -weight 1;               # grid columnconfigure $tab1 
    }
   
    # Bind tabs to specific procs if necessary
    bind $window.hlf.nb  <<NotebookTabChanged>> {
        if { [$::ICBK::gui::window.hlf.nb index current] == 4 } { ::ICBK::gui::updateSummary }
    }

    # End of Notebook

    ### Navigation across tabs
    ttk::frame  $window.hlf.nav
    ttk::button $window.hlf.nav.back -text "Previous" -command {ttk::notebook::CycleTab $::ICBK::gui::window.hlf.nb -1}
    ttk::button $window.hlf.nav.next -text "Next"     -command {ttk::notebook::CycleTab $::ICBK::gui::window.hlf.nb  1}

    grid $window.hlf.nav -column 0 -row 1 -sticky se -padx "0 15" -pady "0 10"
    grid $window.hlf.nav.back $window.hlf.nav.next

    ### End of Navigation across tabs

    ### Size-grip
    #grid [ttk::sizegrip $window.hlf.grip] -sticky se -column 0 -row 3

    ###
    # Tab 1: General info (Project name, work directory, system size and resolution of 3D potentials)

    # Project name, folder, ...
    ttk::frame  $tab1.f1
    ttk::label  $tab1.f1.projlbl     -text "Project name:"   -font TkDefaultFont -width 12
    ttk::label  $tab1.f1.lbl2        -text "Project folder:" -font TkDefaultFont -width 12
    ttk::entry  $tab1.f1.projnme     -textvariable ::ICBK::projectName  -width 30 -font TkTextFont
    ttk::entry  $tab1.f1.name2       -textvariable ::ICBK::workdir      -width 30 -font TkTextFont
    ttk::button $tab1.f1.load        -text "Load Project" -command ::ICBK::gui::loadProject
    ttk::button $tab1.f1.dirbrowse   -text "Browse"       -command ::ICBK::gui::selectWorkDir 
    ttk::button $tab1.f1.dirtemp     -text "Temporary"    -command { set ::ICBK::workdir [::ICBK::gettempdir]; }

    bind $tab1.f1.name2 <Double-1> ::ICBK::gui::selectWorkDir

    # System dimensions

    ttk::frame $tab1.f2
    ttk::frame $tab1.f2.manual
    ttk::frame $tab1.f2.xsc
    ttk::frame $tab1.resolution

    ttk::label $tab1.f2.lbl            -text "System dimensions" -font TkDefaultFont -anchor w
    ttk::label $tab1.f2.xsc.pathlbl    -text "Input XSC file:"   -font TkDefaultFont -width 12
    ttk::label $tab1.f2.manual.bv1     -text "Basis vector 1:"   -font TkDefaultFont -width 12
    ttk::label $tab1.f2.manual.bv2     -text "Basis vector 2:"   -font TkDefaultFont -width 12
    ttk::label $tab1.f2.manual.bv3     -text "Basis vector 3:"   -font TkDefaultFont -width 12
    ttk::label $tab1.f2.manual.origin  -text "Origin:"           -font TkDefaultFont -width 12

    ttk::radiobutton $tab1.f2.mxsc     -value "xsc"    -variable ::ICBK::gui::method -text "eXtended System Configuration (XSC) file"
    ttk::radiobutton $tab1.f2.mman     -value "manual" -variable ::ICBK::gui::method -text "Manual input"

    ttk::entry $tab1.f2.xsc.path    -textvariable ::ICBK::gui::xscfile -width 30 -font TkTextFont
    bind $tab1.f2.xsc.path <Double-1> ::ICBK::gui::browseXscFile
    bind $tab1.f2.xsc.path <1> { set ::ICBK::gui::method "xsc" }
    ttk::button $tab1.f2.xsc.pathBrowse -text "Browse" -command ::ICBK::gui::browseXscFile 

    foreach element {ax ay az bx by bz cx cy cz ox oy oz} {
        set s$element [ttk::entry $tab1.f2.manual.$element -textvariable ::ICBK::$element -width 10 -justify center -font TkTextFont];
        bind $tab1.f2.manual.$element <1> { set ::ICBK::gui::method "manual"}
    }

    # Resolution
    ttk::label $tab1.resolution.lbl -text "Resolution of produced 3D potentials:" -anchor w -font TkDefaultFont
    ttk::entry $tab1.resolution.value -textvariable ::ICBK::resolution -width 5 -justify center  -font TkTextFont
    #spinbox $tab1.resolution.units -values [list \u212B nm] -wrap true -width 5 -justify center

    grid $tab1.f1 -column 0 -sticky nsew -padx 10 -pady "10 0"
    grid $tab1.f1.projlbl $tab1.f1.projnme - $tab1.f1.load -sticky nsew -ipady 2
    grid $tab1.f1.lbl2 $tab1.f1.name2 $tab1.f1.dirbrowse $tab1.f1.dirtemp -sticky nsew -ipady 2

    grid columnconfigure $tab1.f1 {0 1 2 3} -weight 1

    grid $tab1.f2 -column 0 -sticky nsew -padx 10 -pady "10 0"
    grid columnconfigure $tab1.f2 0 -weight 1

    grid $tab1.f2.lbl  -column 0 -row 0 -sticky ew -pady "0 5"
    grid $tab1.f2.mxsc -column 0 -row 1 -sticky nsew
    grid $tab1.f2.xsc  -column 0 -row 2 -sticky nsew
    grid columnconfigure $tab1.f2.xsc {0 1 2} -weight 1  

    grid     $tab1.f2.xsc.pathlbl \
        $tab1.f2.xsc.path \
        $tab1.f2.xsc.pathBrowse -sticky nsew -padx {20 0} -ipady 2

    grid $tab1.f2.mman   -column 0 -row 3 -sticky nsew
    grid columnconfigure $tab1.f2.mman 0 -weight 1  

    grid $tab1.f2.manual -column 0 -row 4 -sticky nsew  -padx {20 0}
    grid $tab1.f2.manual.bv1 $sax $say $saz -sticky nsew  -ipady 1
    grid $tab1.f2.manual.bv2 $sbx $sby $sbz -sticky nsew  -ipady 1
    grid $tab1.f2.manual.bv3 $scx $scy $scz -sticky nsew  -ipady 1
    grid $tab1.f2.manual.origin $sox $soy $soz -sticky nsew  -ipady 1
    grid columnconfigure $tab1.f2.manual {1 2 3} -weight 1

    grid $tab1.resolution -column 0 -sticky nsw -padx 10 -pady 10
    grid $tab1.resolution.lbl $tab1.resolution.value -sticky nsw -ipady 2
    grid columnconfigure $tab1.resolution {0 1} -weight 1  

    # End of Resolution frame
    ###

    # End of Tab1
    ###


    ###
    # Tab 2: Membrane material, nanopore geometry

    # Frame: Membrane material, nanopore geometry

    # Material and geometry
    ttk::frame      $tab2.f1
    ttk::label      $tab2.f1.lmaterial   -text "Membrane material:" -font TkDefaultFont -width 17
    ttk::combobox   $tab2.f1.material -font TkDefaultFont -justify center -width 20 -state readonly

    ttk::label      $tab2.f1.lgeometry   -text "Pore geometry:" -font TkDefaultFont -width 17
    ttk::combobox   $tab2.f1.shape    -font TkDefaultFont -justify center -width 20 -state readonly

    ttk::separator  $tab2.f1.sep1    -orient horizontal
    ttk::label      $tab2.f1.geomopt     -text "Geometry details:" -font TkDefaultFont

    # Read currently known materials
    ::ICBK::readmaterials;
    # creates a list `::ICBK::allmaterials' (list of lists)
    # each entry is a list: <material name> <code>

    # Read currently known shapes
    ::ICBK::readshapes;
    # creates a list `::ICBK::allshapes' (list of lists)
    # each entry is a list: shapeName pathToGridTool option1 option2 ...
    # Option 1 should be membrane thickness
    # Output file (last option) should be omitted

    ::ICBK::gui::populatematerialbox
    ::ICBK::gui::populateshapebox

    $tab2.f1.material configure -values $::ICBK::gui::combomaterials
    $tab2.f1.shape    configure -values $::ICBK::gui::comboshapes

    # bind $tab2.f1.material  <<ComboboxSelected>> { puts "[$::ICBK::gui::window.hlf.nb.tab2.f1.material get]"; }
    bind $tab2.f1.shape     <<ComboboxSelected>> {
        # puts "[$::ICBK::gui::window.hlf.nb.tab2.f1.shape get]";
        ::ICBK::gui::displayShapeOptions;
    }

    $tab2.f1.material current 0
    $tab2.f1.shape    current 0

    # Place everything out
    grid $tab2.f1 -sticky nsew -padx 10 -pady "10 0" -columnspan 2
    grid $tab2.f1.lmaterial $tab2.f1.material -sticky nsw
    grid $tab2.f1.lgeometry $tab2.f1.shape -sticky nsw -pady 3
    grid $tab2.f1.sep1 - -sticky we -pady 10
    grid $tab2.f1.geomopt - -sticky nsew

    # Specify additional options
    grid columnconfigure $tab2.f1 {0 1} -weight 1

    # Now, display geometry options
    ::ICBK::gui::displayShapeOptions



    # End of Tab 2
    ###



    ###
    # Tab 3: Biomolecules

    # Tab 3 objects
    ttk::frame $tab3.f1 
    ttk::label $tab3.f1.label -text "PDB file/code:" -font TkDefaultFont
    ttk::entry $tab3.f1.filename -textvariable ::ICBK::gui::moleculePDB -width 30 -justify center  -font TkTextFont

    ttk::button $tab3.f1.browse -text "Browse" -command ::ICBK::gui::browsePdbFile
    ttk::button $tab3.f1.preview -text "Preiew" -command ::ICBK::gui::previewPdb
    ttk::button $tab3.f1.add -text "Add" -command ::ICBK::gui::addPdbToList

    ttk::label  $tab3.f1.sellab  -text "Atom selection:" -font TkDefaultFont
    ttk::entry  $tab3.f1.sel     -textvar ::ICBK::gui::moleculeSelText  -justify center  -font TkTextFont

#    ttk::checkbutton $tab3.f1.showall -text "Show selection only" -variable ::ICBK::gui::showselectiononly -command ::ICBK::gui::changeView

    ttk::radiobutton $tab3.f1.showall -text "Show all"       -value 0 -variable ::ICBK::gui::showselectiononly -command ::ICBK::gui::changeView
    ttk::radiobutton $tab3.f1.showsel -text "Show Selection" -value 1 -variable ::ICBK::gui::showselectiononly -command ::ICBK::gui::changeView


    ttk::labelframe $tab3.f1.list -text "Biomolecules:" -labelanchor nw
    tk::listbox     $tab3.f1.list.box -height 7 -width 10 -listvariable ::ICBK::gui::biomollist -selectmode single  -exportselection 0
    ttk::scrollbar  $tab3.f1.list.scroll -command [list $tab3.f1.list.box yview] -orient vertical

    ttk::label      $tab3.f1.list.pdblbl -text "PDB file/code:" -font TkDefaultFont
    ttk::label      $tab3.f1.list.pdbval -textvariable ::ICBK::gui::displayPdb  -font TkDefaultFont -anchor w
    ttk::label      $tab3.f1.list.sellbl -text "Atom selection:" -font TkDefaultFont
    ttk::label      $tab3.f1.list.selval -textvariable ::ICBK::gui::displaySel  -font TkDefaultFont -anchor w
    ttk::label      $tab3.f1.list.natlbl -text "Number of atoms:" -font TkDefaultFont
    ttk::label      $tab3.f1.list.natval -textvariable ::ICBK::gui::displayNat  -font TkDefaultFont -anchor w

    ttk::frame      $tab3.f1.list.buttons 
    ttk::button     $tab3.f1.list.buttons.delete -text "Remove" -command ::ICBK::gui::removePdbFromList -width 6
    ttk::button     $tab3.f1.list.buttons.clear  -text "Clear"  -command ::ICBK::gui::clearPdbList -width 6

    ttk::label  $tab3.f1.diellabel   -text "Dielectric constant:" -font TkDefaultFont
    ttk::entry  $tab3.f1.dielvalue   -textvar ::ICBK::dielectric -width 10 -justify center  -font TkTextFont

    ttk::frame       $tab3.f1.fix
    ttk::label       $tab3.f1.fix.label   -text "Use Adaptive Poisson-Boltzmann Solver (APBS) VMD plugin to:" -font TkDefaultFont
    ttk::checkbutton $tab3.f1.fix.charges -text "Fix atomic charges" -variable ::ICBK::fixcharges
    ttk::checkbutton $tab3.f1.fix.radii   -text "Fix atomic radii"   -variable ::ICBK::fixradii

    # Tab 3 defaults and other configurations
    $tab3.f1.list.box configure -yscrollcommand [list $tab3.f1.list.scroll set]

    # Tab 3 bindings
    bind $tab3.f1.filename <Double-1> ::ICBK::gui::browsePdbFile
    bind $tab3.f1.filename <Return> ::ICBK::gui::previewPdb
    bind $tab3.f1.sel <Return> ::ICBK::gui::changeView
    bind $tab3.f1.list.box <<ListboxSelect>> ::ICBK::gui::updateBiomolInfoPanel
    #bind $tab3.f1.list.box <FocusOut> ::ICBK::gui::clearBiomolSelection 

    # Tab 3 layout
    grid $tab3.f1 -sticky nsew -padx 10 -pady 10
      grid $tab3.f1.label  $tab3.f1.filename $tab3.f1.browse $tab3.f1.add -sticky nsew -padx 2 -ipady 2
      grid $tab3.f1.sellab $tab3.f1.sel $tab3.f1.preview -sticky nsew -padx 2 -ipady 2
      grid $tab3.f1.add -rowspan 2

      grid $tab3.f1.showall $tab3.f1.showsel -sticky nsw

      grid $tab3.f1.list  -columnspan 4 -pady 10 -ipadx 5 -sticky nsew
        grid $tab3.f1.list.box    -row 0 -column 0 -rowspan 5 -pady 5 -padx "5 0" -sticky nsew
        grid $tab3.f1.list.scroll -row 0 -column 1 -rowspan 5 -pady 5 -padx "0 5" -sticky nsew
        grid $tab3.f1.list.pdblbl -row 0 -column 2 -sticky nsew
        grid $tab3.f1.list.pdbval -row 0 -column 3 -sticky nsew -padx "10 0"
        grid $tab3.f1.list.sellbl -row 1 -column 2 -sticky nsew
        grid $tab3.f1.list.selval -row 1 -column 3 -sticky nsew -padx "10 0"
        grid $tab3.f1.list.natlbl -row 2 -column 2 -sticky nsew
        grid $tab3.f1.list.natval -row 2 -column 3 -sticky nsew -padx "10 0"
        grid $tab3.f1.list.buttons -column 0 -sticky nsew 
        grid $tab3.f1.list.buttons.delete $tab3.f1.list.buttons.clear -sticky nsew -padx 2 -ipady 2

      grid $tab3.f1.fix  -row 4 -columnspan 4 -sticky nsw -pady "0 10" -ipadx 5
        grid $tab3.f1.fix.label -sticky nsew
        grid $tab3.f1.fix.charges -sticky nsw -ipady 2 -padx "50 0"
        grid $tab3.f1.fix.radii -sticky nsw -ipady 2 -padx "50 0"

      grid $tab3.f1.diellabel  $tab3.f1.dielvalue -sticky nsw -padx 2 -ipady 2

    # Tab 3 layout options
    grid columnconfigure $tab3.f1 {1 2} -weight 1
    grid columnconfigure $tab3.f1.list 3 -weight 1
    grid columnconfigure $tab3.f1.list.buttons {0 1} -weight 1

    # Tab 3 -> end



    # Tab 4: BD particles
    ttk::frame      $tab4.f1
    ttk::label      $tab4.f1.namel -text "Brownian Particle" -anchor w -font TkDefaultFont
    ttk::combobox   $tab4.f1.namecb -font TkDefaultFont -justify center -width 20 -state readonly
    ttk::label      $tab4.f1.quanl -text "Quantity" -anchor w -font TkDefaultFont
    ttk::entry      $tab4.f1.quanv -width 10 -justify center  -font TkTextFont
    ttk::button     $tab4.f1.add -width 7 -text "Add" -command ::ICBK::gui::addBDparticleToList
    #    ttk::separator  $tab4.f1.sep -orient horizontal

    ttk::labelframe $tab4.f2 -text "Selected Brownian Particles:" -labelanchor nw
    tk::listbox     $tab4.f2.listbox -height 10 -width 20 -listvariable ::ICBK::gui::bdparts -selectmode single  -exportselection 0
    ttk::scrollbar  $tab4.f2.scroll -command [list $tab4.f2.listbox yview] -orient vertical

    ttk::label      $tab4.f2.nmblbl -text "Quantity:"    -font TkDefaultFont
    ttk::label      $tab4.f2.chrlbl -text "Charge:"     -font TkDefaultFont
    ttk::label      $tab4.f2.diflbl -text "Diffusion:"  -font TkDefaultFont
    ttk::label      $tab4.f2.radlbl -text "Radius:"     -font TkDefaultFont
    ttk::label      $tab4.f2.epslbl -text "Epsilon:"    -font TkDefaultFont
    ttk::label      $tab4.f2.nmbval -textvariable ::ICBK::gui::displayNum -font TkDefaultFont -anchor w
    ttk::label      $tab4.f2.chrval -textvariable ::ICBK::gui::displayChr -font TkDefaultFont -anchor w
    ttk::label      $tab4.f2.difval -textvariable ::ICBK::gui::displayDif -font TkDefaultFont -anchor w
    ttk::label      $tab4.f2.radval -textvariable ::ICBK::gui::displayRad -font TkDefaultFont -anchor w
    ttk::label      $tab4.f2.epsval -textvariable ::ICBK::gui::displayEps -font TkDefaultFont -anchor w

    ttk::frame      $tab4.f2.buttons 
    ttk::button     $tab4.f2.buttons.delete -text "Remove" -command ::ICBK::gui::removeBDParticleFromList -width 6
    ttk::button     $tab4.f2.buttons.clear  -text "Clear"  -command ::ICBK::gui::clearBDParticleList -width 6


    ttk::frame      $tab4.f3
    ttk::label      $tab4.f3.totnumlbl -text "Total Number of Brownian Particles:" -font TkDefaultFont
    ttk::label      $tab4.f3.totnumval -textvariable ::ICBK::gui::displayTotalNumber -font TkDefaultFont -anchor w
    ttk::label      $tab4.f3.totchrlbl -text "Total Charge of Brownian Particles:" -font TkDefaultFont
    ttk::label      $tab4.f3.totchrval -textvariable ::ICBK::gui::displayTotalCharge -font TkDefaultFont -anchor w


    ::ICBK::readbdparticles; # reads in ions.dat -> creates ::ICBK::listofbdparticles
    ::ICBK::gui::populateparticlebox; # populate ::ICBK::gui::comboparticles
    $tab4.f1.namecb  configure -values $::ICBK::gui::comboparticles
    $tab4.f2.listbox configure -yscrollcommand [list $tab4.f2.scroll set]
    bind $tab4.f2.listbox <<ListboxSelect>> ::ICBK::gui::updateBDInfoPanel

    # Tab 4 layout
    grid $tab4.f1 -sticky nsew
    grid $tab4.f1.namel $tab4.f1.quanl -sticky nsew
    grid $tab4.f1.namecb $tab4.f1.quanv $tab4.f1.add -sticky nsew
    #    grid $tab4.f1.sep - - -sticky we -pady "10 0"

    grid $tab4.f2 -sticky nsew
    grid $tab4.f2.listbox    -row 0 -column 0 -rowspan 5 -pady 5 -padx "5 0" -sticky nsew
    grid $tab4.f2.scroll     -row 0 -column 1 -rowspan 5 -pady 5 -padx "0 5" -sticky nsew
    grid $tab4.f2.nmblbl -row 0 -column 2 -sticky nsew
    grid $tab4.f2.nmbval -row 0 -column 3 -sticky nsew -padx "10 0"
    grid $tab4.f2.chrlbl -row 1 -column 2 -sticky nsew
    grid $tab4.f2.chrval -row 1 -column 3 -sticky nsew -padx "10 0"
    grid $tab4.f2.diflbl -row 2 -column 2 -sticky nsew
    grid $tab4.f2.difval -row 2 -column 3 -sticky nsew -padx "10 0"
    grid $tab4.f2.radlbl -row 3 -column 2 -sticky nsew
    grid $tab4.f2.radval -row 3 -column 3 -sticky nsew -padx "10 0"
    grid $tab4.f2.epslbl -row 4 -column 2 -sticky nsew
    grid $tab4.f2.epsval -row 4 -column 3 -sticky nsew -padx "10 0"

    grid $tab4.f2.buttons -column 0 -sticky nsew
    grid $tab4.f2.buttons.delete $tab4.f2.buttons.clear  -sticky nsew -padx 2 -ipady 2

    grid $tab4.f3 -sticky nsew -column 0 -sticky nsw -padx 10 -pady 10
    grid $tab4.f3.totnumlbl $tab4.f3.totnumval
    grid $tab4.f3.totchrlbl $tab4.f3.totchrval

    # special layout options (paddings and stuff)
    grid $tab4.f1 -padx 10 -pady 10
    grid $tab4.f2 -padx 10
    grid $tab4.f1.namel -ipadx 10

    # configure grid resizing
    grid columnconfigure $tab4.f1 {0 1} -weight 1
    grid columnconfigure $tab4.f2 3 -weight 1


    # Tab 6
    ttk::labelframe  $tab6.f1 -text "BD model overview" -labelanchor nw
    ttk::label $tab6.f1.label1   -text "Project name:" -font TkTextFont
    ttk::label $tab6.f1.label2   -text "Project folder:" -font TkTextFont
    ttk::label $tab6.f1.label3   -text "System dimensions:" -font TkTextFont
    ttk::label $tab6.f1.label4   -text "Resolution of grid-based potentials:" -font TkTextFont
    ttk::label $tab6.f1.label5   -text "Membrane material:" -font TkTextFont
    ttk::label $tab6.f1.label6   -text "Pore geometry:" -font TkTextFont
    ttk::label $tab6.f1.label7   -text "Geometry options:" -font TkTextFont
    ttk::label $tab6.f1.label8   -text "Biomolecules:" -font TkTextFont
    ttk::label $tab6.f1.label9   -text "Number of biomolecules:" -font TkTextFont
    ttk::label $tab6.f1.label10  -text "Dielectric constant:" -font TkTextFont
    ttk::label $tab6.f1.label11  -text "Brownian (point) particles:" -font TkTextFont
    ttk::label $tab6.f1.label12  -text "Number of Brownian particles:" -font TkTextFont

    ttk::label $tab6.f1.value1   -textvariable ::ICBK::projectName -font TkTextFont
    ttk::label $tab6.f1.value2   -textvariable ::ICBK::workdir -font TkTextFont
    ttk::label $tab6.f1.value3   -textvariable ::ICBK::gui::sysdimstring -font TkTextFont
    ttk::label $tab6.f1.value4   -textvariable ::ICBK::resolution -font TkTextFont
    ttk::label $tab6.f1.value5   -textvariable ::ICBK::gui::material -font TkTextFont
    ttk::label $tab6.f1.value6   -textvariable ::ICBK::gui::shape -font TkTextFont
    ttk::label $tab6.f1.value7   -textvariable ::ICBK::gui::shapeoptions -font TkTextFont
    ttk::label $tab6.f1.value8   -textvariable ::ICBK::gui::biomolnames -font TkTextFont
    ttk::label $tab6.f1.value9   -textvariable ::ICBK::gui::nbiomol -font TkTextFont
    ttk::label $tab6.f1.value10  -textvariable ::ICBK::dielectric -font TkTextFont
    ttk::label $tab6.f1.value11  -textvariable ::ICBK::gui::brownparticles -font TkTextFont
    ttk::label $tab6.f1.value12  -textvariable ::ICBK::gui::displayTotalNumber -font TkTextFont

    grid $tab6.f1 -sticky nsew -padx 10 -pady "10 0"
    for {set i 1} {$i <=12} {incr i} { grid $tab6.f1.label$i $tab6.f1.value$i -sticky nsw }
   
    grid columnconfigure $tab6.f1 {0 1} -weight 1

    ttk::frame      $tab6.f2
    ttk::label      $tab6.f2.efieldlabel  -text "Electric bias, mV:" -font TkDefaultFont
    ttk::entry      $tab6.f2.efieldvalue  -textvariable ::ICBK::efieldmV  -width 8 -font TkTextFont -justify center

    ttk::button     $tab6.f2.save       -text "Save"   -command ::ICBK::gui::saveProject
    ttk::label      $tab6.f2.savelabel  -text "Save Current Project." -font TkDefaultFont

    ttk::button     $tab6.f2.build      -text "Build" -command ::ICBK::gui::buildBDmodel
    ttk::label      $tab6.f2.buildlabel -text "Build Brownian Dynamics model with the above parameters." -font TkDefaultFont

    ttk::button     $tab6.f2.run        -text "Start"   -command ::ICBK::gui::startBDsim
    ttk::label      $tab6.f2.runlabel   -text "Start Brownian Dynamics simulations NOW (on this machine)." -font TkDefaultFont

    grid $tab6.f2 -sticky nsew -padx 10 -pady 10 -ipadx 10 -ipady 10
      grid $tab6.f2.efieldlabel $tab6.f2.efieldvalue -sticky nsw -ipady 2 -pady 2
      grid $tab6.f2.build $tab6.f2.buildlabel -sticky nsew -ipady 2
      grid $tab6.f2.save  $tab6.f2.savelabel  -sticky nsew -ipady 2
      grid $tab6.f2.run   $tab6.f2.runlabel   -sticky nsew -ipady 2

      grid $tab6.f2.build  -padx "0 10"
      grid $tab6.f2.save   -padx "0 10"
      grid $tab6.f2.run    -padx "0 10"

    grid columnconfigure $tab6.f2 {0 1 2} -weight 1

    # Main window
    return $window; # without this return statement main window will not be reopened
}



##########
# PROCS

proc ::ICBK::gui::browseXscFile {} {
    set ::ICBK::gui::method "xsc"
    set xscType { {{XSC and XST files} {.xsc .xst}} {{All Files} *} } ; # list of extensions to select XSC/XST files
    set tempfile [tk_getOpenFile -title "Select XSC/XST File" -initialdir $::ICBK::workdir -multiple 0 -filetypes $xscType]
    if {![string eq $tempfile ""]} {
        set ::ICBK::gui::xscfile $tempfile
        ::ICBK::processXscFile
    }
}

proc ::ICBK::gui::browsePdbFile {} {
    set pdbType { {{Protein Data Bank files} {.pdb}} {{All Files} *} } ; # list of extensions to select PDB files
    set tempfile [tk_getOpenFile -title "Select PDB File" -multiple 0 -filetypes $pdbType]
    if {![string eq $tempfile ""]} {
        set ::ICBK::gui::moleculePDB $tempfile
        if {$tempfile != $::ICBK::gui::previewMolPdb} { set ::ICBK::gui::moleculeSelText "all"; }
        ::ICBK::gui::previewPdb
    }
}

proc ::ICBK::gui::clearBiomolSelection {} {
    $::ICBK::gui::window.hlf.nb.tab3.f1.list.box selection clear 0 end
    set ::ICBK::gui::biomollistselectindex -1
    set ::ICBK::gui::moleculePDB ""
    set ::ICBK::gui::moleculeSelText "all"
    ::ICBK::gui::clearBiomolInfoPanel
}

proc ::ICBK::gui::clearBiomolInfoPanel {} {
    set ::ICBK::gui::displayPdb ""
    set ::ICBK::gui::displaySel ""
    set ::ICBK::gui::displayNat ""
}

proc ::ICBK::gui::clearBDParticleSelection {} {
    $::ICBK::gui::window.hlf.nb.tab4.f2.listbox selection clear 0 end
    set ::ICBK::gui::bdparticleselectindex -1
    ::ICBK::gui::clearBDInfoPanel
}

proc ::ICBK::gui::clearBDInfoPanel {} {
    set ::ICBK::gui::displayNum ""
    set ::ICBK::gui::displayChr ""
    set ::ICBK::gui::displayDif ""
    set ::ICBK::gui::displayRad ""
    set ::ICBK::gui::displayEps ""
}

proc ::ICBK::gui::addPdbToList {} {

# Attempt to preview molecule
# return "0" if no error has occured, "1" otherwise
    if {![::ICBK::gui::previewPdb]} {
    # Successfully loaded molecule
        set sel  [atomselect $::ICBK::gui::previewMol "$::ICBK::gui::moleculeSelText"]
        set natoms [$sel num]
        $sel delete
        if {$natoms == 0} {
            tk_messageBox -icon warning -message "Error!" -detail "Selection contains 0 atoms!"
            return
        } else {
            lappend ::ICBK::pdbList [list $::ICBK::gui::moleculePDB $::ICBK::gui::moleculeSelText $natoms]
            # lappend ::ICBK::molSelections $sel
            lappend ::ICBK::gui::biomollist "[file tail $::ICBK::gui::moleculePDB]";# "Molecule $::ICBK::gui::biomolcounter"
            incr    ::ICBK::gui::nbiomol

            mol rename $::ICBK::gui::previewMol "[file tail $::ICBK::gui::moleculePDB]" ; #"Molecule $::ICBK::gui::biomolcounter"
            lappend ::ICBK::gui::biomolpdblist $::ICBK::gui::previewMol                 ; # avoid re-loading molecules that were added to the [final] list 
            mol off $::ICBK::gui::previewMol

            # forget the preview
            set ::ICBK::gui::previewMol    "";
            set ::ICBK::gui::previewMolPdb "";
            set ::ICBK::gui::previewMolSel "";

            # clear text fields
            set ::ICBK::gui::moleculePDB ""
            set ::ICBK::gui::moleculeSelText "all"

            # Increment the counter of loaded biomolecules
            #incr ::ICBK::gui::biomolcounter
        }
    }
}


proc ::ICBK::gui::addBDparticleToList {} {
    # tab 4 shortcut
    set tab4 $::ICBK::gui::window.hlf.nb.tab4

    # Get global index of currently chosen BDparticle in the combobox of particles
    set bdidx  [$tab4.f1.namecb current]
    set bdname [$tab4.f1.namecb get]

    # Get the number of particles user specified; stop if user specified not-a-number
    set userInput [$tab4.f1.quanv get]
    if {! [string is integer -strict $userInput]} { return; }

    # Current number of brownian particles of this type
    set curnum [lindex $::ICBK::numberofbdparticles $bdidx]
    if {! [string is integer -strict $curnum]} {
        tk_messageBox -message "Error!" -detail "This should never happen!\nSee ::ICBK::gui::addBDparticleToList.";
        return;
    }; # this should NEVER happen, but... check if curnum is nonsense

    # Compute the new value
    set newnum [expr {$curnum + $userInput}]

    # If the new value is less than zero...
    # Set it to zero
    if {$newnum < 0} { set newnum 0 }

    # So, how many particles are we adding/subtracting? 
    # Needed for update of total charge
    set numdiff [expr {$newnum - $curnum}]

    # Update the number of particles
    lset ::ICBK::numberofbdparticles $bdidx $newnum

    # Particle charge
    set q [lindex $::ICBK::listofbdparticles $bdidx end-3]

    # Update total particle count
    set ::ICBK::gui::displayTotalNumber [expr {$::ICBK::gui::displayTotalNumber + $numdiff}]

    # Update total charge
    set ::ICBK::gui::displayTotalCharge [expr {$::ICBK::gui::displayTotalCharge + $q*$numdiff}]

    # Make text color "red" if total charge is not zero
    set color "black"
    if {$::ICBK::gui::displayTotalCharge != 0.0 } { set color "red"; }
    $tab4.f3.totchrval configure -foreground $color

    # If number of particles is zero
    # Remove particle from the displayed list
    if {$newnum == 0} {
        if {$bdidx in $::ICBK::gui::bddisplayindices} {
            set idd [lsearch -exact $::ICBK::gui::bddisplayindices $bdidx]
            set ::ICBK::gui::bddisplayindices [lreplace $::ICBK::gui::bddisplayindices $idd $idd]
            set ::ICBK::gui::bdparts [lreplace $::ICBK::gui::bdparts $idd $idd]
            ::ICBK::gui::clearBDInfoPanel
        }
    } else {
        # Now, all numbers are already there.
        # We need to create a nice output for user to see
        # If particle is not currently in the displayed list
        if {$bdidx ni $::ICBK::gui::bddisplayindices} {
            lappend ::ICBK::gui::bddisplayindices $bdidx; # First, add its INDEX to the list of displayed BD particles
            lappend ::ICBK::gui::bdparts $bdname
        }
    }

    # Update particle info panel if it is selected
    if {[$tab4.f2.listbox curselection] != ""} {
        set ::ICBK::gui::bdparticleselectindex -1; 
        # pretend nothing was selected.
        # Otherwise, updateBDInfoPanel just clears up list selection
        ::ICBK::gui::updateBDInfoPanel
    }

    # Update total charge counter


}

# Tab 4 - "Remove" button
proc ::ICBK::gui::removeBDParticleFromList {} {
    # tab 4 shortcut
    set tab4 $::ICBK::gui::window.hlf.nb.tab4
    
    # Get index of currently chosen BDparticle in the listbox of particles
    set idx [$tab4.f2.listbox curselection]

    # If nothing selected - stop
    if {$idx == ""} { return }

    # bdx = Global index of the BD particle that is highlighted in the list
    set bdx [lindex $::ICBK::gui::bddisplayindices $idx]

    # How many particles are we removing?
    set num [lindex $::ICBK::numberofbdparticles $bdx]

    # Set number of BD particles of this type to zero
    lset ::ICBK::numberofbdparticles $bdx 0 

    # Remove
    set ::ICBK::gui::bddisplayindices [lreplace $::ICBK::gui::bddisplayindices $idx $idx]
    set ::ICBK::gui::bdparts [lreplace $::ICBK::gui::bdparts $idx $idx]

    # Clear right info panel
    ::ICBK::gui::clearBDInfoPanel

    # Forget what was selected
    set ::ICBK::gui::bdparticleselectindex -1;

    # Charge or particle that is being deleted
    set q [lindex $::ICBK::listofbdparticles $bdx end-3]

    # Update total particle count
    set ::ICBK::gui::displayTotalNumber [expr {$::ICBK::gui::displayTotalNumber - $num}]

    # Update total charge
    set ::ICBK::gui::displayTotalCharge [expr {$::ICBK::gui::displayTotalCharge - $q*$num}]
    $tab4.f3.totchrval configure -foreground black
}

proc ::ICBK::gui::clearBDParticleList {} {
    # Remove all
    set ::ICBK::gui::bddisplayindices ""
    set ::ICBK::gui::bdparts ""

    # Clear right info panel
    ::ICBK::gui::clearBDInfoPanel

    # Forget what was selected
    set ::ICBK::gui::bdparticleselectindex -1;

    # Set total particle count to 0
    set ::ICBK::gui::displayTotalNumber 0

    # Set total charge to zero
    set ::ICBK::gui::displayTotalCharge 0.0

    # Reset numbers of participating particles
    set ::ICBK::numberofbdparticles [lrepeat [llength $::ICBK::listofbdparticles] 0]
}

proc ::ICBK::gui::previewPdb {{pdb ""} {sel ""}} {

    set curmolnum [molinfo num]

    # If proc is called without arguments
    # default to what is specified in GUI (PDB/SEL) entry boxes
    if {$pdb == ""} { set pdb $::ICBK::gui::moleculePDB; }

    # Stop if PDB is still empty
    if {$pdb == ""} {return 1}

    # If no selection has been specified, default to what was provided in GUI box
    if {$sel == ""} { set sel $::ICBK::gui::moleculeSelText; }

    # If still empty, choose all
    if {$sel == ""} { set sel "all"; }

    # if molecule hasn't changed
    # then check if the selection has changed and update preview if necessary
    if {$pdb == $::ICBK::gui::previewMolPdb} {
        if {$sel != $::ICBK::gui::previewMolSel} { ::ICBK::gui::changeView $::ICBK::gui::previewMol $sel; }
        return 0;
    }

    # At this point, molecule we preview something new.

    foreach mol $::ICBK::gui::biomolpdblist { mol off $mol }

    # Try to load new molecule
    if { [catch {mol new $pdb waitfor all} tmp] } {
        tk_messageBox -icon error -message "Error!" -detail "Could not load \"$pdb\"!"

        # If number of molecules hasn't changed - exit
        if {[molinfo num] == $curmolnum} { return 1; }
        
        # Currently, when VMD fails to load pdb from PDB website, it still creates a molecule with 0 atoms
        # Following line deletes that empty molecule
        if {[molinfo top get numatoms] == 0} { mol delete top };
        return 1;
    
    } else {
    # Success

    # Delete current molecule if available
        if {$::ICBK::gui::previewMol != ""} { mol delete $::ICBK::gui::previewMol }
        set ::ICBK::gui::previewMol    $tmp
        set ::ICBK::gui::previewMolPdb $pdb
        mol rename $::ICBK::gui::previewMol "Molecule Preview"
        ::ICBK::gui::changeView
        scale by 0.5

    }
    return 0;
}

proc ::ICBK::gui::changeView {{mol ""} {sel ""}} {

    # First, check if we have preview molecule
    if {$mol == ""} { set mol $::ICBK::gui::previewMol }

    # If not, check if we have something selected in the list of biomolecules
    if {$mol == ""} {
        set index [$::ICBK::gui::window.hlf.nb.tab3.f1.list.box curselection]
        if {$index == ""} { return 1;}
        set mol [lindex $::ICBK::gui::biomolpdblist $index]
    }

    # If neither is true, return an error
    if {$mol == ""} { return 1; }

    if {$sel == ""} { set sel $::ICBK::gui::moleculeSelText }
    set ::ICBK::gui::previewMolSel $sel

    # Delete all reps
    set n [molinfo $mol get numreps]
    for {set i 0} {$i < $n} {incr i} { mol delrep 0 $mol }

    # All - lines ;# TODO: update representations, don't delete them. Always make two reps, hide the second when requested
    if {! $::ICBK::gui::showselectiononly} {
        mol selection {all}
        mol color Name
        mol representation Lines
        mol material Opaque
        mol addrep $mol
    }

    # Selection - Licorice
    mol selection $sel
    mol color Name
    mol representation Licorice
    mol material Opaque
    mol addrep $mol

    return 0;
}

proc ::ICBK::gui::removePdbFromList {} {
    set list $::ICBK::gui::window.hlf.nb.tab3.f1.list.box

    if {[$list size] > 0} {
        set idx [$list curselection]
        if {$idx>=0} {
            set ::ICBK::gui::biomollist    [lreplace $::ICBK::gui::biomollist    $idx $idx]
            set ::ICBK::pdbList            [lreplace $::ICBK::pdbList            $idx $idx]
            
            #[lindex $::ICBK::molSelections $idx] delete
            #set ::ICBK::molSelections      [lreplace $::ICBK::molSelections      $idx $idx]
            
            mol delete [lindex $::ICBK::gui::biomolpdblist $idx]
            set ::ICBK::gui::biomolpdblist [lreplace $::ICBK::gui::biomolpdblist $idx $idx]

            if {$idx > 0} {
                set n [expr {$idx - 1}]
                $list see $n
                $list selection anchor $n
            }

        }
    }
    if {[llength $::ICBK::pdbList] == 0} { ::ICBK::gui::clearPdbList } \
        else { ::ICBK::gui::clearBiomolSelection }
}

proc ::ICBK::gui::clearPdbList {} {
    ::ICBK::gui::clearBiomolSelection

    set ::ICBK::gui::biomollist ""
    set ::ICBK::pdbList ""

    #foreach sel $::ICBK::molSelections {$sel delete}
    #set ::ICBK::molSelections ""

    #set ::ICBK::gui::biomolcounter 0
    set ::ICBK::gui::moleculePDB ""
    set ::ICBK::gui::moleculeSelText "all"
    foreach mol $::ICBK::gui::biomolpdblist { mol delete $mol }
}


# Called when user selects a molecule from the list of already loaded molecules
proc ::ICBK::gui::updateBiomolInfoPanel {} {
    set listbox $::ICBK::gui::window.hlf.nb.tab3.f1.list.box
    set index "[$listbox curselection]"


    # Compensating for the lack of <<ListboxChange>>
    # If user clicks on currently selected item, deselect it
    if {$index == $::ICBK::gui::biomollistselectindex} {
        ::ICBK::gui::clearBiomolSelection;
        foreach mol $::ICBK::gui::biomolpdblist { mol off $mol }
        return;
    }
    set ::ICBK::gui::biomollistselectindex $index;

    # When list is empty, index is ""
    if {$index != ""} {
        $listbox see $index

        # Update output info on the right hand side
        set ::ICBK::gui::displayPdb [lindex $::ICBK::pdbList $index 0]
        set ::ICBK::gui::displaySel [lindex $::ICBK::pdbList $index 1]
        set ::ICBK::gui::displayNat [lindex $::ICBK::pdbList $index 2]

        # Populate PDB/SEL entry widgets
        set ::ICBK::gui::moleculePDB $::ICBK::gui::displayPdb
        set ::ICBK::gui::moleculeSelText $::ICBK::gui::displaySel

        # Preview selected molecule
        foreach mol $::ICBK::gui::biomolpdblist { mol off $mol }
        mol on  [lindex $::ICBK::gui::biomolpdblist $index]
        mol top [lindex $::ICBK::gui::biomolpdblist $index]

        ::ICBK::gui::changeView [lindex $::ICBK::gui::biomolpdblist $index]
        display resetview
        scale by 0.5

        ## Change text on button "Add" to "Change"
        #$::ICBK::gui::window.hlf.nb.tab3.f1.add configure -text "Change"
    } 
}


proc ::ICBK::gui::updateBDInfoPanel {} {
    # tab4 listbox shortcut
    set listbox $::ICBK::gui::window.hlf.nb.tab4.f2.listbox

    # current selection index in listbox
    set index "[$listbox curselection]"

    # Compensate for the lack of <<ListboxChange>>
    # If user clicks on currently selected item, deselect it
    if {$index == $::ICBK::gui::bdparticleselectindex} {
        ::ICBK::gui::clearBDParticleSelection;
        return;
    }

    set ::ICBK::gui::bdparticleselectindex $index;

    if {$index != ""} {
        $listbox see $index

        # Update output info on the right hand side
        set bdidx [lindex $::ICBK::gui::bddisplayindices $index]
        set ::ICBK::gui::displayNum [lindex $::ICBK::numberofbdparticles $bdidx]
        set ::ICBK::gui::displayChr [lindex $::ICBK::listofbdparticles $bdidx end-3]
        set ::ICBK::gui::displayDif [lindex $::ICBK::listofbdparticles $bdidx end-2]
        set ::ICBK::gui::displayRad [lindex $::ICBK::listofbdparticles $bdidx end-1]
        set ::ICBK::gui::displayEps [lindex $::ICBK::listofbdparticles $bdidx end]
    } else {
        ::ICBK::gui::clearBDInfoPanel
    }
}

proc ::ICBK::processXscFile {} {
    foreach el {ax ay az bx by bz cx cy cz ox oy oz} { variable $el}
    foreach {ax ay az bx by bz cx cy cz ox oy oz} [::ICBK::readxsc $::ICBK::gui::xscfile] { break }
}

proc ::ICBK::gui::selectWorkDir {} {
    set tempdir [tk_chooseDirectory -title "Select project folder" -initialdir [pwd]]
    if {![string eq $tempdir ""]} { set ::ICBK::workdir $tempdir }
}

proc ::ICBK::gui::populatematerialbox {} {
    set ::ICBK::gui::combomaterials {}
    foreach entry $::ICBK::allmaterials {
        lappend ::ICBK::gui::combomaterials [lindex $entry 0]
    }
}

proc ::ICBK::gui::populateparticlebox {} {
    set ::ICBK::gui::comboparticles {}
    foreach entry $::ICBK::listofbdparticles {
        lappend ::ICBK::gui::comboparticles [lrange $entry 0 end-5]
    }
}

proc ::ICBK::gui::populateshapebox {} {
    set ::ICBK::gui::comboshapes {}
    foreach entry $::ICBK::allshapes {
        lappend ::ICBK::gui::comboshapes [lindex $entry 0]
    }
}


proc ::ICBK::gui::displayShapeOptions {args} {

    if {![string eq $args "preserveoptions"] || [string eq $args "{}"]} {
        unset -nocomplain ::ICBK::shapeoption
    }
    set tab2 $::ICBK::gui::window.hlf.nb.tab2

    # Destroy the frame with options displayed before
    catch {destroy $tab2.f2}
    ttk::frame $tab2.f2; # -relief solid -borderwidth 1


    # Get current index of the "shape" in the shapebox
    set shape_index [$tab2.f1.shape current]

    # Load up all info we have for that shape
    set ::ICBK::gui::currentShapeInfo [lindex $::ICBK::allshapes $shape_index]
    #set all_shape_info [lindex $::ICBK::allshapes $shape_index]

    # Get all options for that shape
    # index 0 - shape name
    # index 1 - grid tool
    # index 2, 3, ... - options
    set options  [lrange $::ICBK::gui::currentShapeInfo 2 end]
    #puts "Options: $options"

    set nopt 0; # index of a shape option
    foreach option $options {
        ttk::label $tab2.f2.lbl$nopt -text $option -font TkDefaultFont -anchor w
        ttk::entry $tab2.f2.val$nopt -textvariable ::ICBK::shapeoption($nopt) -justify center -width 10  -font TkTextFont

        grid $tab2.f2.lbl$nopt $tab2.f2.val$nopt -sticky nsw -pady 3
        grid $tab2.f2.lbl$nopt -padx "10 2"
        grid $tab2.f2.val$nopt -padx "2 10"
        incr nopt
    }

    ttk::separator  $tab2.f2.vsep -orient vertical
    grid $tab2.f2.vsep -column 2 -row 0 -rowspan $nopt -sticky nsew -padx 5

    # Destroy the frame with an image
    catch {destroy $tab2.f3}
    ttk::frame $tab2.f3
    set imageFile  [lindex $::ICBK::shapeImages $shape_index]

    if {[file readable $imageFile]} {
        set image  [image create photo -file $imageFile]
        set width  [image width $image] 
        set height [image height $image]
        #puts "Image $imageFile: $width x $height"
        #puts "Frame size: [winfo width $tab2.f3] x [winfo height $tab2.f3]"
        set size 300
        if {$width > $size || $height > $size} {
            set scw   [expr {int(ceil($width  *1.0/$size))}]
            set sch   [expr {int(ceil($height *1.0/$size))}]
            set scale [expr {$scw > $sch ? $scw : $sch}]

            set width  [expr {$width / $scale}]
            set height [expr {$height / $scale}]

            set newimage [image create photo -format gif -width $width -height $height]
            $newimage copy $image -subsample $scale $scale -shrink -to 0 0 $width $height
            image delete $image
            set image $newimage
        }

        canvas $tab2.f3.canvas -height $height -width $width -bg #EDEDED -highlightthickness 0
        $tab2.f3.canvas create image 0 0 -anchor nw -image $image

        grid $tab2.f3.canvas -row 0 -column 2 -rowspan $nopt -sticky nsew
    }

    grid $tab2.f2 $tab2.f3 -padx "0 10"
    grid $tab2.f2 -column 0 -sticky nsw -padx "30 0" -pady "0 10"
    grid $tab2.f3 -column 1 -sticky nw

    grid columnconfigure $tab2.f2 0 -weight 0
    grid columnconfigure $tab2.f2 1 -weight 1
    grid columnconfigure $tab2.f3 2 -weight 0
}


proc ::ICBK::gui::updateSummary {} {
    set ::ICBK::gui::sysdimstring "($::ICBK::ax, $::ICBK::ay, $::ICBK::az),  ($::ICBK::bx, $::ICBK::by, $::ICBK::bz),  ($::ICBK::cx, $::ICBK::cy, $::ICBK::cz)"
    set ::ICBK::gui::sysvolume 0.0
    set ::ICBK::gui::material "[$::ICBK::gui::window.hlf.nb.tab2.f1.material get]"
    set ::ICBK::gui::shape "[$::ICBK::gui::window.hlf.nb.tab2.f1.shape get]"
    set ::ICBK::gui::shapeoptions ""
    for {set i 0} {$i < [array size ::ICBK::shapeoption]} {incr i} {
        if {$i > 0} { append ::ICBK::gui::shapeoptions ", "; }
        if {[string length [string trim $::ICBK::shapeoption($i)]] == 0} {
            append ::ICBK::gui::shapeoptions " - "
        } else {
            append ::ICBK::gui::shapeoptions $::ICBK::shapeoption($i)
        }
    }
    set ::ICBK::gui::biomolnames ""
    for {set i 0} {$i < [llength $::ICBK::pdbList]} {incr i} {
        if {$i > 0} { append ::ICBK::gui::biomolnames ", " }; 
        append ::ICBK::gui::biomolnames [file tail [lindex $::ICBK::pdbList $i 0]]
    }
    set ::ICBK::gui::nbiomol [llength $::ICBK::pdbList]

    set ::ICBK::gui::brownparticles ""
    foreach index $::ICBK::gui::bddisplayindices {
        if {[string length [string trim $::ICBK::gui::brownparticles]] >0 } { append ::ICBK::gui::brownparticles ", "; }
        append ::ICBK::gui::brownparticles "[lrange [lindex $::ICBK::listofbdparticles $index] 0 end-5] [lindex $::ICBK::numberofbdparticles $index]"
    }

    set ::ICBK::prefix [file normalize [file join $::ICBK::workdir $::ICBK::projectName]]
}

proc ::ICBK::gui::buildBDmodel {} {
    puts "[string repeat * 80]"
    puts "ICBK: Brownian Dynamics Toolkit"

    # Membrane material
    set midx [$::ICBK::gui::window.hlf.nb.tab2.f1.material current]
    if {$midx == ""} { tk_messageBox -icon error -message "Fatal error!" -detail "Failed to find selected material"; return }
    set mcode [lindex $::ICBK::allmaterials $midx end]
    puts "ICBK: Membrane: [$::ICBK::gui::window.hlf.nb.tab2.f1.material get]";# ($mcode)

    # Find 1D interaction potentials of Brownian particles with membrane
    # Necessary for producing 3D membrane-particle potential
    puts "ICBK: Searchig for membrane -- BD particles potentials"
    unset -nocomplain membranepotential
    foreach index $::ICBK::gui::bddisplayindices {
        set icode [lindex $::ICBK::listofbdparticles $index end-4]
        set membranepotential($icode) [::ICBK::findPotential $icode $mcode]
        puts "ICBK: -- found $membranepotential($icode)"
    }

    # Find bounding box and use it as new system dimensions
    puts "ICBK: Checking simulation box size"
    foreach {min max} [::ICBK::boundingbox] {break}
    set size [vecsub $max $min]
    ::ICBK::initializeDimensions
    foreach el {ax ay az bx by bz cx cy cz ox oy oz} { variable ::ICBK::$el }
    foreach {ax by cz} $size {break}

    # Check if dimensions are right
    # We require that grids have at least 
    # 3 points along each direction 
    puts "ICBK: Verifying system dimensions"
    foreach s [list $ax $by $cz] {
        if {$s < 3*$::ICBK::resolution} {
            tk_messageBox -icon error -message "Error!" -detail "System dimensions are too small!"
            return;
        }
    }

    # System dimensions should be fine by now
    # Update summary since dimensions could have changed
    ::ICBK::gui::updateSummary

    # Write an xsc file that will be used by pmepot (basis.xsc)
    #puts "ICBK: Preparing basis xsc file"
    set prefix [file normalize [file join $::ICBK::workdir $::ICBK::projectName]]
    set ::ICBK::prefix $prefix
    #::ICBK::writexsc $prefix.basis.xsc

    # write similar test file (basis.txt) that will be used by grid-tools
    # TODO: make grid-tools read xsc files
    puts "ICBK: Preparing basis file"
    if {![catch {open $prefix.basis.txt "w"} ch]} {
        puts $ch "$ax $ay $az\n$bx $by $bz\n$cx $cy $cz\n$ox $oy $oz"
        close $ch
    }

    # Write the zero grid
    puts "ICBK: Generating basis grid"
    puts "ICBK: $::ICBK::gridNew $prefix.basis.txt $::ICBK::resolution $prefix.zero.dx"
    exec $::ICBK::gridNew $prefix.basis.txt $::ICBK::resolution $prefix.zero.dx

    if {![file readable $prefix.zero.dx]} {
        tk_messageBox -icon error -message "Error!" -detail "Could not create zero grid."
        return;
    } else {
        set ::ICBK::basisgridfile "$prefix.zero.dx"
    }

    # Generate grid of minimum distances to the surface    
    puts "ICBK: Creating minimum distance-to-surface grid:"
    set toolName [lindex $::ICBK::gui::currentShapeInfo 1]
    set toolNanopore [file normalize [file join $::env(ICBKDIR) tools $toolName]]
    set options ""
    for {set n 0} {$n < [array size ::ICBK::shapeoption]} {incr n} { append options " $::ICBK::shapeoption($n)" }
    puts "ICBK: $toolNanopore $::ICBK::basisgridfile $options $prefix.min_distance.dx"
    exec $toolNanopore $::ICBK::basisgridfile {*}$options $prefix.min_distance.dx

    if {![file readable $prefix.min_distance.dx]} {
        tk_messageBox -icon error -message "Error!" -detail "Could not create distance-to-surface grid."
        # return;
    } else {
        set ::ICBK::mindistgrid "$prefix.min_distance.dx"
    }

    # Generate nanopore grid for selected Brownian particles
    puts "ICBK: Creating membrane/nanopore grids for Brownian particles"
    foreach index $::ICBK::gui::bddisplayindices {
        set icode [lindex $::ICBK::listofbdparticles $index end-4]
        puts "ICBK: $icode: $::ICBK::gridDistToPot $::ICBK::mindistgrid $membranepotential($icode) $prefix.nanopore.$icode.dx"
        exec $::ICBK::gridDistToPot $::ICBK::mindistgrid $membranepotential($icode) $prefix.nanopore.$icode.dx

        if {![file readable $prefix.nanopore.$icode.dx]} {
            tk_messageBox -icon error -message "Error!" -detail "Failed to create nanopore grid for: [lrange [lindex $::ICBK::listofbdparticles $index] 0 end-5]"
            # return;
        } else {
            set ::ICBK::nanoporegrid($icode) "$prefix.nanopore.$icode.dx"
        }
    }


    # Process biomolecules
    if {$::ICBK::gui::nbiomol > 0} {
        # (1) Fix charges/radii
        #     Create:
        # (2) Hard-sphere repulsion potentials
        # (3) Long-range electrostatics potentials
        # (4) Short-range electrostatics potentials
        # (5) Diffusivity maps ( dx.doi.org/10.1021/jp210641j )


        # Fix charges/radii using APBS (code snippet from PMEPot)
        if {$::ICBK::fixcharges || $::ICBK::fixradii} {
            if {! [catch {package require apbsrun} version]} {
                for {set i 0} {$i < $::ICBK::gui::nbiomol} {incr i} {
                    set mol [lindex $::ICBK::gui::biomolpdblist $i]
                    set sel [atomselect $mol [lindex $::ICBK::pdbList $i 1]]
                    if {$::ICBK::fixcharges} { ::APBSRun::set_parameter_charges $sel; puts "APBS: fixed charges."; }
                    if {$::ICBK::fixradii}   { ::APBSRun::set_parameter_radii   $sel; puts "APBS: fixed radii."; }
                    $sel delete
                }
            }
        }


        # Create *one* file with radii and charges of all biomolecules' atoms
        # Will be used to create:
        # hard sphere repulsion maps
        # short/long- range electrostatics maps
        for {set i 0} {$i < $::ICBK::gui::nbiomol} {incr i} {
            set mol [lindex $::ICBK::gui::biomolpdblist $i]
            set sel [atomselect $mol [lindex $::ICBK::pdbList $i 1]]
            #set sel [lindex $::ICBK::molSelections $i]
            foreach zero {0} {set rqxyzList [$sel get {radius charge x y z}]}
            $sel delete

            if {[file exists $prefix.hard.dat]} {file delete $prefix.hard.dat}
            if {[file exists $prefix.charges.dat]} {file delete $prefix.charges.dat}

            if {![catch {open $prefix.hard.dat a} ch1] && 
                ![catch {open $prefix.charges.dat a} ch2] } {
                foreach rqxyz $rqxyzList {
                    foreach {r q x y z} $rqxyz {break}
                    puts $ch1 "$r $x $y $z"
                    puts $ch2 "$q $x $y $z"
                }
                close $ch1
                close $ch2
                puts "ICBK: wrote [lindex $::ICBK::pdbList $i 2] coordinates to $prefix.hard.dat"
                puts "ICBK: wrote [lindex $::ICBK::pdbList $i 2] charges     to $prefix.charges.dat"
            }
        }

        # Hard-sphere repulsion map
        puts -nonewline "ICBK: creating hard-sphere repulsion map ($prefix.hard.dx)"
        exec $::ICBK::gridAddRepulsion $::ICBK::basisgridfile $prefix.hard.dat 40 1 $prefix.hard.dx
        puts " - done!"

        if {![file readable $prefix.hard.dx]} {
            tk_messageBox -icon error -message "Error!" -detail "Failed to create $prefix.hard.dx"
            # return;
        } else {
            set ::ICBK::hardgrid "$prefix.hard.dx"
        }

        # Short-range electrostatics map
        # TODO: doublecheck that we need to divide the coulombConst by the dielectric constant.
        # Check #1: Yes, we do.
        puts -nonewline "ICBK: creating short-range electrostatic map ($prefix.charges.dx)"
        set coulombConst [expr {167100.76/$::ICBK::temperature/$::ICBK::dielectric}]; #  [coulombconst*e^2/AA] -> kT >
        exec $::ICBK::gridAddCoulomb $::ICBK::basisgridfile $prefix.charges.dat $coulombConst $prefix.charges.dx
        puts " - done!"

        if {![file readable $prefix.charges.dx]} {
            tk_messageBox -icon error -message "Error!" -detail "Failed to create $prefix.charges.dx"
            # return;
        } else {
            set ::ICBK::chargegrid "$prefix.charges.dx"
        }

        # Long-range electrostatic (PME)
        puts "ICBK: creating long-range electrostatic map"
        if {! [catch {package require pmepot} version]} {
            set pmeGrids ""

            foreach el {ax ay az bx by bz cx cy cz ox oy oz} { variable ::ICBK::$el }
            set a [list $ax $ay $az]; set b [list $bx $by $bz];
            set c [list $cx $cy $cz]; set o [list $ox $oy $oz];
            set center [vecsub $o [vecscale 0.5 [lrepeat 3 $::ICBK::resolution]]];
            # This is where we compensate for the mismatch in definitions of grids between PMEPot and our tools
            # In our definition,    first grid point = (center) - 0.5*(size)
            # In PMEpot definition, first grid point = (center) - 0.5(size) + 0.5*resolution
            #
            # Last grid point = (first grid point) + (size), so
            # our definition,    last grid point = (center) + 0.5*(size)
            # PMEPot definition, last grid point = (center) + 0.5*(size) + 0.5*resolution

            for {set i 0} {$i < $::ICBK::gui::nbiomol} {incr i} {
                set mol [lindex $::ICBK::gui::biomolpdblist $i]
                set sel [atomselect $mol [lindex $::ICBK::pdbList $i 1]]

                pmepot -cell [list $center $a $b $c] -ewaldfactor 0.25 -grid $::ICBK::resolution \
                    -sel $sel -loadmol none -dxfile $prefix.pme$i.tmp.dx

                # Scale pmepot result to units of kT, for T = ::ICBK::temperature
                # PMEPot: diel = 1, kT for T = 300 K
                set scaleFactor [expr {300.0/$::ICBK::temperature/$::ICBK::dielectric}];
                exec $::ICBK::gridScaleShift $prefix.pme$i.tmp.dx $scaleFactor 0.0 $prefix.pme$i.dx

                file delete $prefix.pme$i.tmp.dx
                append pmeGrids " $prefix.pme$i.dx"
            }

            if {$::ICBK::gui::nbiomol == 1} {
                # We have just one biomolecule
                
                # clean-up after previous run.
                # TODO: check if directory is clean *before* running anything
                if {[file exists $prefix.pme.dx]} { file delete $prefix.pme.dx; }
                file rename $prefix.pme0.dx $prefix.pme.dx
            } else {
                # We have more than one biomolecule

                exec $::ICBK::gridAddSame $pmeGrids $prefix.pme.dx

                if {[file readable $prefix.pme.dx]} {
                    for {set i 0} {$i < $::ICBK::gui::nbiomol} {incr i} { file delete $prefix.pme$i.dx }
                    set ::ICBK::pmegrid "$prefix.pme.dx"
                }
                puts "ICBK: created long-range electrostatics map: $prefix.pme.dx"
            }
        }


        # Now, combine all grids:
        # $prefix.total.dx =  $prefix.hard.dx + $prefix.charges.dx + $prefix.pme.dx
        puts "ICBK: $::ICBK::gridAddSame $prefix.hard.dx $prefix.charges.dx $prefix.pme.dx $prefix.total.dx"
        exec $::ICBK::gridAddSame $prefix.hard.dx $prefix.charges.dx $prefix.pme.dx $prefix.total.dx

        if {[file readable $prefix.total.dx]} { set ::ICBK::totalgrid "$prefix.total.dx"; }


        # Now generate diffusivity maps
        foreach index $::ICBK::gui::bddisplayindices {
            set icode  [lindex $::ICBK::listofbdparticles $index end-4]
            set eps    [lindex $::ICBK::listofbdparticles $index end] 
            set radius [lindex $::ICBK::listofbdparticles $index end-1] 

            exec $::ICBK::gridAtomSurfaceDistance $::ICBK::basisgridfile $prefix.hard.dat $eps $prefix.vdw_dist.$icode.dx
            exec $::ICBK::gridDecayFunction       $prefix.vdw_dist.$icode.dx $radius 100 2.93 $prefix.diffusion.$icode.dx
            # 100 and 2.93 are from the empirical fit found for K+ and Cl- ions near DNA from all-atom MD simulations
            # See: dx.doi.org/10.1021/jp210641j | J. Phys. Chem. C 2012, 116, 3376 - 3393 
            # pages: 3382 - 3383
            puts "ICBK: Created diffusivity map $prefix.diffusion.$icode.dx"
            file delete $prefix.vdw_dist.$icode.dx

            if {[file readable $prefix.diffusion.$icode.dx]} { set ::ICBK::diffusiongrid($icode) "$prefix.diffusion.$icode.dx"; }
        }
    }    

    # Combine all grids for every type of BD particles
    foreach index $::ICBK::gui::bddisplayindices {
        
        set icode  [lindex $::ICBK::listofbdparticles $index end-4]

        # If there is a file whose name is the same as the one we are going to use, delete it.
        if {[file exists $prefix.grid.$icode.dx]} { file delete $prefix.grid.$icode.dx; }


        set a [expr { [info exists ::ICBK::totalgrid] && [file readable $::ICBK::totalgrid] } ]
        set b [expr { [info exists ::ICBK::nanoporegrid($icode)] && [file readable $::ICBK::nanoporegrid($icode)] } ]

        if {$a && $b} {
            exec $::ICBK::gridAddSame $::ICBK::totalgrid  $::ICBK::nanoporegrid($icode)  $prefix.grid.$icode.dx
        } elseif {$a} {
            file copy $prefix.total.dx $prefix.grid.$icode.dx;
        } elseif {$b} {
            file rename $prefix.nanopore.$icode.dx $prefix.grid.$icode.dx
        } else {
            puts "Failed to locate $::ICBK::totalgrid and $::ICBK::nanoporegrid($icode)"
        }

        if {[file readable $prefix.grid.$icode.dx]} { set ::ICBK::finalgrid($icode) $prefix.grid.$icode.dx; }


    }


    foreach index $::ICBK::gui::bddisplayindices {
        set icode  [lindex $::ICBK::listofbdparticles $index end-4]
        if {![catch {mol new $::ICBK::finalgrid($icode)} molid]} {
            lappend ::ICBK::gui::finalgridlist $molid
            mol rename $molid "$icode potential grid"
            mol modmaterial 0 $molid water
            mol modstyle 0 $molid Isosurface 4.0 0 2 0 1 1
            mol modcolor 0 $molid Volume 0
            mol inactive $molid
        }
    }

}

proc ::ICBK::gui::saveProject {args} {
# Save vars and arrays

    set nargs [llength $args]

    # When there are too many arguments
    if {$nargs > 1} {
        tk_messageBox -icon warning -message "Warning!" -detail "Incorrect project name" -type ok;
        return 0;
    }

    # Without arguments - ask for name
    if {$nargs == 0} {
        set icbkType { {{ICBK Project Files} {.icbk}} {{All Files} *} } ; # list of extensions
        
        set tempfile [tk_getSaveFile -title "Select ICBK Project File" \
            -initialdir $::ICBK::workdir -filetypes $icbkType \
            -initialfile "$::ICBK::projectName.icbk" \
            -defaultextension "icbk"]
        
        if {[string eq $tempfile ""]} { return 0; }
        
        ::ICBK::gui::saveProject $tempfile
    }

    # If we passed an empty string, it becomes "{}"
    # So, check for that
    if {[string eq $args "{}"]} {
        ::ICBK::gui::saveProject;
        return 0;
    }

    set ::ICBK::statefilename $args
    puts $::ICBK::statefilename

    if {[file exists $::ICBK::statefilename]} {
        set answer [tk_messageBox   -icon question \
            -message "“[file tail $::ICBK::statefilename]” already exists.\nDo you want to replace it?" \
            -detail "A file with the same name already exists.\nReplacing it will overwrite its current contents." \
            -type yesno]
        switch -- $answer {
            yes {  }
            no  { return 0 }
        }
    }

    if {[catch {open $::ICBK::statefilename w} ch]} { return 0; }

    foreach v [lsort "[info vars ::ICBK::*] [info vars ::ICBK::gui::*]"] {
        if [array exists $v] {
            puts $ch [list array set $v [array get $v]]
        } else {
            puts $ch [list set $v [set $v]]
        }
    }
    close $ch
}


proc ::ICBK::gui::loadProject {} {
    set icbkType { {{ICBK Project Files} {.icbk}} {{All Files} *} } ; # list of extensions
    set tempfile [tk_getOpenFile -title "Select ICBK Project File" -initialdir $::ICBK::workdir -multiple 0 -filetypes $icbkType]

    if {[string eq $tempfile ""]} { return 0; }

    set statefile $tempfile

    source $statefile

    # Reload biomolecules that are used in the model
    set ::ICBK::gui::biomolpdblist {}
    foreach pdbEntry $::ICBK::pdbList {
        set pdb [lindex $pdbEntry 0];
        set sel [lindex $pdbEntry 1];
        if { ![catch {mol new $pdb waitfor all} tmp] } {
            lappend ::ICBK::gui::biomolpdblist $tmp;
            ::ICBK::gui::changeView $tmp $sel
        } else {
            # Molecule that is specified in 'pdbList' does not exist
            # Request if we want to forget this pdb or replace it with something else
            set answer [tk_messageBox -icon warning -message "Error!" \
                             -detail "Could not load $pdb. Do you want to specify a different file?" \
                             -type yesno]

            switch -- $answer {
                no  {
                    # User requested to forget this (missing) molecule
                    # So, we need to clean-up a bit
                    set idx [lsearch $::ICBK::pdbList $pdbEntry];
                    set ::ICBK::pdbList [lreplace $::ICBK::pdbList $idx $idx];
					set ::ICBK::gui::biomollist [lreplace $::ICBK::gui::biomollist $idx $idx]
                    incr ::ICBK::gui::nbiomol -1
                    continue;
                }
                yes {
                    # User requested to specify a (new) molecule instead of a missing one
                    tk_messageBox -message "Info" -detail "Not there yet!" -type ok;
                }
            }

        }
    }; # END of loading back molecules

    set shapeidx [lsearch -exact $::ICBK::gui::comboshapes $::ICBK::gui::shape]
    $::ICBK::gui::window.hlf.nb.tab2.f1.shape current $shapeidx
    ::ICBK::gui::displayShapeOptions preserveoptions

    # Reload generated Nanopore grids (if any)
    # ::ICBK::finalgrid($icode)
    foreach index $::ICBK::gui::bddisplayindices {
        set icode  [lindex $::ICBK::listofbdparticles $index end-4]
        if {![catch {mol new $::ICBK::finalgrid($icode)} molid]} {
            lappend ::ICBK::gui::finalgridlist $molid
            mol rename $molid "Pore potential: $icode"
            mol modmaterial 0 $molid water
            mol modstyle 0 $molid Isosurface 4.0 0 2 0 1 1
            mol modcolor 0 $molid Volume 0
            mol inactive $molid
        }
    }

}

proc ::ICBK::gui::saveConfig {} {
    set bdTypes { {{Brownian dynamics configuration file} {.bd}} {{All Files} *} } ;
    set tmpfile [tk_getSaveFile -title "Select Configuration File" -filetypes $bdTypes -initialdir $::ICBK::workdir -initialfile "$::ICBK::projectName.bd" -defaultextension "bd"]
    if {[string eq $tmpfile ""]} { return 0; }

    ::ICBK::writeConfig $tmpfile
}


proc ::ICBK::writeConfig {filename} {
    if {[catch {open $filename w} ch]} { return 0; }

    puts $ch "timestep 1e-05"
    puts $ch "steps 50000"
    puts $ch "numberFluct 0"
    puts $ch "interparticleForce 1"
    puts $ch "fullLongRange 1"
    puts $ch "kT 1.0"
    puts $ch "electricField [expr {0.039337309 * $::ICBK::efieldmV / $::ICBK::cz}]" ; # mV/AA -> kT/AA/e
    puts $ch "outputPeriod 50"
    puts $ch "outputEnergyPeriod 500"
    puts $ch "outputFormat dcd"
    puts $ch "cutoff 900.0"
    puts $ch "currentSegmentZ $::ICBK::cz"
    #  puts $ch "inputCoordinates"
    #  puts $ch "decompPeriod 10"

    unset -nocomplain ordering 

    set i 0

    foreach index $::ICBK::gui::bddisplayindices {
        set icode [lindex $::ICBK::listofbdparticles $index end-4]
        set inum  [lindex $::ICBK::numberofbdparticles $index]

        puts $ch "\n# [lrange [lindex $::ICBK::listofbdparticles $index] 0 end-5]"
        puts $ch "particle $icode"
        puts $ch "num $inum"
        puts $ch "gridFile $::ICBK::finalgrid($icode)"

        if {$::ICBK::gui::nbiomol > 0 && [info exists ::ICBK::diffusiongrid($icode)] && [file readable $::ICBK::diffusiongrid($icode)]} {
            puts $ch "diffusionGridFile $::ICBK::diffusiongrid($icode)"
        } else {
            puts $ch "diffusion [lindex $::ICBK::listofbdparticles $index end-2]"
        }
        puts $ch "charge [lindex $::ICBK::listofbdparticles $index end-3]"
        puts $ch "radius [lindex $::ICBK::listofbdparticles $index end-1]"
        puts $ch "eps [lindex $::ICBK::listofbdparticles $index end]"

        set ordering($icode) $i
        incr i
    }

    puts $ch "\ntabulatedPotential  1"

    foreach index $::ICBK::gui::bddisplayindices {
        set icode [lindex $::ICBK::listofbdparticles $index end-4]
        set i $ordering($icode)

        foreach jndex $::ICBK::gui::bddisplayindices {
            set jcode [lindex $::ICBK::listofbdparticles $jndex end-4]
            set j $ordering($jcode)

            if {$j < $i} { continue }
            set pot [::ICBK::findPotential $icode $jcode]
            puts $ch "tabulatedFile $i@$j@$pot"
        }
    }

    close $ch
    set ::ICBK::configfile $filename
}


proc ::ICBK::gui::startBDsim {} {

    ::ICBK::gui::saveConfig

    exec $::ICBK::runbrowntown -r 4 -i $::ICBK::configfile $::ICBK::prefix [clock seconds] & 

    # Wait for the PDB file to be created
    # Thats when we know we can start attempts to establish IMD connection
    set pdbfile $::ICBK::prefix.0.dcd.pdb; # Use 0 replica for IMD
    while {[catch {mol new $pdbfile autobonds off waitfor all} molid]} { sleep 1.0; }

    # Wait one more second before proceeding
    sleep 1.0;

    # Set representations
    mol rename $molid "IMD: $::ICBK::projectName"

    #TODO: make loop over particle types
    mol modselect 0 $molid name POT
    mol modstyle 0 $molid VDW 0.3 50.0
    mol modmaterial 0 $molid AOShiny
    mol modcolor 0 $molid ColorID 7

    mol addrep $molid
    mol modselect 1 $molid name CLA
    mol modstyle 1 $molid VDW 0.3 50.0
    mol modmaterial 1 $molid AOShiny
    mol modcolor 1 $molid ColorID 32

    set sel [atomselect top "name POT"]
    $sel set radius 1.705
    $sel delete

    set sel [atomselect top "name CLA"]
    $sel set radius 2.513
    $sel delete

    scale by 0.5
    rotate x by -60

    # Wait one more second before proceeding
    sleep 1;

    # Try to establish IMD connection
    # Increase wait time by one second between attempts
    while {[catch {imd connect localhost 71992} status]} { sleep [incr time]; }
}


proc ::ICBK::initialize {} {

    ### BD program
    set ::ICBK::runbrowntown     [file normalize [file join $::env(ICBKDIR) program runBrownCUDA]]

    ### Grid tools
    set ::ICBK::gridAddSame      [file normalize [file join $::env(ICBKDIR) tools gridAddSame]]
    set ::ICBK::gridNew          [file normalize [file join $::env(ICBKDIR) tools gridNew]]
    set ::ICBK::gridDistToPot    [file normalize [file join $::env(ICBKDIR) tools gridDistToPot]]
    set ::ICBK::gridAddRepulsion [file normalize [file join $::env(ICBKDIR) tools gridAddRepulsion]]
    set ::ICBK::gridAddCoulomb   [file normalize [file join $::env(ICBKDIR) tools gridAddCoulomb]]
    set ::ICBK::gridScaleShift   [file normalize [file join $::env(ICBKDIR) tools gridScaleShift]]
    set ::ICBK::gridAtomSurfaceDistance [file normalize [file join $::env(ICBKDIR) tools gridAtomSurfaceDistance]]
    set ::ICBK::gridDecayFunction       [file normalize [file join $::env(ICBKDIR) tools gridDecayFunction]]
    
    ### Tab 1
    set ::ICBK::projectName "BrownDyn"
    set ::ICBK::statefilename ""
    set ::ICBK::workdir [pwd]
    set ::ICBK::resolution 0.5

    ::ICBK::initializeDimensions

    ### Tab 3
    set ::ICBK::pdbList ""
    set ::ICBK::molSelections ""
    set ::ICBK::dielectric  114.0
    set ::ICBK::temperature 295.0
    set ::ICBK::fixcharges 1
    set ::ICBK::fixradii 1

    ### Tab 6
    set ::ICBK::efieldmV 0.0

}

proc ::ICBK::initialize_gui {} {

    # Now, we have Prefs options for OS X only
    if {[string eq "Darwin" $::tcl_platform(os)]} {
        set ::ICBK::gui::showadvanced 1
    }

    ### Tab 1 
    set ::ICBK::gui::method "xsc"

    ### Tab 2
    set ::ICBK::gui::combomaterials ""
    set ::ICBK::gui::currentShapeInfo ""
    unset -nocomplain ::ICBK::shapeoption

    ### Tab 3
    set ::ICBK::gui::moleculePDB ""
    set ::ICBK::gui::moleculeSelText "all"
    set ::ICBK::gui::previewMol ""
    set ::ICBK::gui::previewMolPdb ""
    set ::ICBK::gui::previewMolSel ""
    set ::ICBK::gui::biomollistselectindex -1; # Compensating for the lack of <<ListboxChange>>
    set ::ICBK::gui::biomolpdblist ""; # list of loaded molecules
    set ::ICBK::gui::biomollist "";    # list of loaded molecules
    set ::ICBK::gui::showselectiononly 0
    set ::ICBK::gui::displayPdb ""
    set ::ICBK::gui::displaySel ""
    set ::ICBK::gui::displayNat ""
    
    ### Tab 4
    set ::ICBK::gui::displayTotalCharge 0.0
    set ::ICBK::gui::displayTotalNumber 0
    set ::ICBK::gui::bddisplayindices ""
    set ::ICBK::gui::bdparts ""
    set ::ICBK::gui::bdparticleselectindex -1
    set ::ICBK::gui::displayNum ""
    set ::ICBK::gui::displayChr ""
    set ::ICBK::gui::displayDif ""
    set ::ICBK::gui::displayRad ""
    set ::ICBK::gui::displayEps ""

    ### Tab 6
    set ::ICBK::gui::finalgridlist {}

}


proc ::ICBK::unloadMolecules {} {
    # previewMol can be either
    foreach mol [lsort -unique \
                            [concat $::ICBK::gui::biomolpdblist \
                                    $::ICBK::gui::previewMol \
                                    $::ICBK::gui::finalgridlist]] {
        catch {mol delete $mol}
    }
}

proc ::ICBK::newProject {} {
    ::ICBK::initialize
    ::ICBK::initialize_gui
}



### Fonts available in Ttk
# TkDefaultFont          The default for all GUI items not otherwise specified.
# TkTextFont             Used for entry widgets, listboxes, etc.
# TkFixedFont            A standard fixed-width font.
# TkMenuFont             The font used for menu items.
# TkHeadingFont          The font typically used for column headings in lists and tables.
# TkCaptionFont          A font for window and dialog caption bars.
# TkSmallCaptionFont     A smaller caption font for subwindows or tool dialogs
# TkIconFont             A font for icon captions.
# TkTooltipFont          A font for tooltips
