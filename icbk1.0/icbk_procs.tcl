proc ::ICBK::doEverything {args} {
    set dir "$::env(ICBKDIR)"
    package require psfgen
    set molID [::ICBK::loadPdb "$dir/NTL9.pdb"]
    ::ICBK::combinePoreProtein "$molID"
    resetpsf
    ::ICBK::writeDistanceGrid {}
    resetpsf
    ::ICBK::readDistanceGrid {}
    resetpsf
    ::ICBK::predictCurrent    
}


# Load a molecule
proc ::ICBK::loadPdb {args} {
    set nargs [llength $args]
    if {$nargs != 1} {puts "Error! No pdb filename entered."; return -1}

    set pdb [lindex $args 0]
    if {![catch {mol new $pdb} caught]} {	
	set molID [molinfo top]
	return $molID
    } else {
	puts "Error! pdb file named $pdb not successfully loaded."
	return -1
    }	      
}


# generate the psf and pdb file of protein
proc ::ICBK::combinePoreProtein {args} {
    set proname $::env(ICBKDIR)/proteinTemp

    set nargs [llength $args]
    if {$nargs != 1} {puts "Error! No molecule ID specified."; return -1}

    set molID [lindex $args 0]
    set chains [lsort -unique [[atomselect $molID all] get chain]]
    foreach chain $chains {
	[atomselect $molID "chain $chain"] writepdb $proname-$chain.pdb
    }
    package require psfgen
    resetpsf
    topology $::env(ICBKDIR)/top_all36_prot.rtf
    pdbalias residue HOH TIP3
    pdbalias atom TIP3 O OH2
    pdbalias atom TIP3 OW OH2
    pdbalias atom ILE CD1 CD
    pdbalias residue HIS HSE
    foreach chain $chains {
       segment $chain {
         #first NTER
         #first none
         #last none
         pdb $proname-$chain.pdb
       }
       coordpdb $proname-$chain.pdb $chain
    }
    regenerate angles dihedrals
    guesscoord
    writepsf $proname-final.psf
    writepdb $proname-final.pdb
    mol delete all

    # combine graphene channel
    resetpsf
    readpsf $::env(ICBKDIR)/nanopore.psf
    coordpdb $::env(ICBKDIR)/nanopore.pdb
    readpsf $proname-final.psf
    coordpdb $proname-final.pdb
    writepsf $::env(ICBKDIR)/gra+pro.psf
    writepdb $::env(ICBKDIR)/gra+pro.pdb
    resetpsf
 
}


# Make a dx file which evaluates the distance from the protein at each point
proc ::ICBK::writeDistanceGrid {args} {
    set workingDir $::env(ICBKDIR)
    set startFrame 0
    set stride 1
    set df 1
 
    mol load psf $workingDir/gra+pro.psf pdb $workingDir/gra+pro.pdb
 
    set nFrames [molinfo top get numframes]
    puts [format "Reading %i frames." $nFrames]   
 
   # Move forward, computing                                        
    for {set f $startFrame} {$f < $nFrames} {incr f $df}  {
	molinfo top set frame $f
	package require pbctools
	pbc set {{80.0    0.0   0.0} {0.0     80.0   0.0} {0.0    0.0  40.176}} -namd -now ;#-alignx
	pbc wrap -molid top -sel all -center origin
	set m [expr $f]   
	set sel [atomselect top "all and sqrt(x**2+y**2)<=33"]
	volmap distance $sel -res 1 -cutoff 100 -minmax {{-33 -33 -20.0} {33 33 20.0}} -o $workingDir/f-$m.dx
	$sel delete
	puts "$m"
    }
}


proc ::ICBK::readDistanceGrid {args} {
    set workingDir $::env(ICBKDIR)
    puts $workingDir
    set cutz0 -20.0 ;#left boundary
    set cutz1 20.0  ;#right boundary  
    set r 30.0    ;#unit A
    set kmin 0
    set kmax 1  ;#######[[[[[[must change]]]]]]]
    set dk 1    ;#######[[[[[[must change]]]]]]]
    for {set k $kmin} {$k < $kmax} {incr k $dk} {
	#puts "$k"
	set file [open $workingDir/f-$k.dx r]                          
	set output [open $workingDir/f-$k.dat w]              
	#initial the parameters to calculate the coordinates
	#
	set j 0
	#store the coordinates and values of each grid to arrays
	while { [gets $file line] != -1 } {
	    if {[ lindex $line 0] == "object" & [ lindex $line 1] == 1 } {
		set nx [ lindex $line 5]
		set ny [ lindex $line 6]
		set nz [ lindex $line 7]
		#puts "nx= $nx ny= $ny nz= $nz"
          }
	    if {[ lindex $line 0] == "origin"} {
		set xorigin [ lindex $line 1]
		set yorigin [ lindex $line 2]
		set zorigin [ lindex $line 3]
		#puts "xorigin= $xorigin yorigin= $yorigin zorigin= $zorigin"
	    }
	    if {[ lindex $line 0] == "delta" & [ lindex $line 1] != 0} {
		set xdelta [ lindex $line 1]
		#puts "xdelta= $xdelta"
	    }
	    if {[ lindex $line 0] == "delta" & [ lindex $line 1] == 0 & [ lindex $line 2] != 0} {
		set ydelta [ lindex $line 2]
		#puts "ydelta= $ydelta"
	    }
	    if {[ lindex $line 0] == "delta" & [ lindex $line 1] == 0 & [ lindex $line 2] == 0 & [ lindex $line 3] != 0} {
		set zdelta [ lindex $line 3]
             #puts "zdelta= $zdelta"
	    }
	    if { [ lindex $line 0] != "#" & [ lindex $line 0] != "object" & [ lindex $line 0] != "origin" & [ lindex $line 0] != "delta"}  {
             set m [llength $line]
		for {set n 0} {$n < $m} {incr n} { 
		    set v($j) [lindex $line $n]    ;#store the value of that grid
		    set iz  [expr $j%$nz]
		    set iy  [expr ($j/$nz)%$ny]
		    set ix  [expr $j/($nz*$ny)]
		    set z($j) [expr $zorigin+$iz*$zdelta]
		    set y($j) [expr $yorigin+$iy*$ydelta]
		    set x($j) [expr $xorigin+$ix*$xdelta]
		    if {sqrt($x($j)**2+$y($j)**2) <= $r && $z($j) <= $cutz1 && $z($j) >= $cutz0} {
			puts $output "$x($j) $y($j) $z($j) $v($j)"
		    }       
		    incr j
		}
	    }
	}
	#puts "$j"
	close $file 
	close $output
    }
}


proc ::ICBK::predictCurrent {args} {
    set workingDir $::env(ICBKDIR)
    ########parameter is:a=4.1 b=0.25
    set kmin 0
    set kmax 1   ;########[[[[[[[[[[must change]]]]]]]]]]
    set dk 1     ;########[[[[[[[[[[must change]]]]]]]]]]
    set output [open $workingDir/f-smd.dat w]   ;########[[[[[[[[[[must change]]]]]]]]]] 
    set dir .  ;########[[[[[[[[[[must change]]]]]]]]]] 
    set e 2.718281828
    
    #set the initial a and b and increasement of a and b
    set amin 3.3
    set da 10.05
    set amax 5.0
    
    set bmin 0.809
    set db 10.05
    set bmax 1.0
    
    set cmin 0.24
    set dc 10.0
    set cmax 0.3
    
    #openpore current parameters 
    set dl 1.0    ;#bin length of nanochannel along z direction
    set cutz0 -20.0 ;#left boundary
    set cutz1 20.0  ;#right boundary   
    set E [expr 300.0/40.176]  ;#unit mv/A
    set V [expr $E*($cutz1-$cutz0)]   ;#unit mv
    set r 30.0    ;#unit A
    set n [expr  int(($cutz1-$cutz0)/$dl)]  
    set pi 3.141592654
    set S [expr $pi*$r*$r]
    set I 62.5106    ;#unit nA
    set rou [expr $V*$S/$I/($cutz1-$cutz0)]
    set sigma [expr 1/$rou]
    set dcdfreq 1000   ;#
    set timestep 0.3    ;#1 ns
    #bin of each piece used for maxim's equation
    set bin 1.0
    set n0 [expr int(($r+1)/$bin)]
    
    for {set k $kmin} {$k < $kmax} {incr k $dk} {
	set file [open $workingDir/f-$k.dat r]  ;#######[[[[must be changed]]]]
	set i 0
	while { [gets $file line] != -1 } {    
	    set x($i) [ lindex $line 0]
	    set y($i) [ lindex $line 1]
	    set z($i) [ lindex $line 2]
	    set v($i) [ lindex $line 3]
	    incr i   
	}
	set num $i
	set bingrid [expr $dl*$num/($cutz1-$cutz0)]  ;#unit 1
	#puts "bingrid= $bingrid"
	##storage data at the begining
	for {set m1 0} {$m1 < $n} {incr m1}  {
	    set j 0
	    #set the boundary
	    set left [expr $cutz0+$m1*$dl]
	    set right [expr $cutz0+($m1+1)*$dl]
	    for {set m3 0} {$m3 < $num} {incr m3} {
		if {$z($m3) > $left && $z($m3) <= $right} {           
               set gridx($m1-$j) $x($m3)
		    set gridy($m1-$j) $y($m3)
		    set gridz($m1-$j) $z($m3)
		    set gridv($m1-$j) $v($m3)
		    incr j
		}
	    }  
	    set count $j        ;#tell the number of grids for each pieces          
	}
	#puts $num
	#puts $count
	if {1} {    ;#used to adjust the script
	    #loop the a and b
	    set disWbin 0
	    set opdisR 0.0          ;# inverse of R
	    set totalR 0.0  
	    set i 0
	    for {set a $amin} {$a < $amax} {set a [expr $a+$da]} { 
		for {set b $bmin} {$b < $bmax} {set b [expr $b+$db]} {
		    for {set c $cmin} {$c < $cmax} {set c [expr $c+$dc]} {
			# Move forward, computing                                    
			for {set m1 0} {$m1 < $n} {incr m1} {   ;#cut pieces along axis
			    for {set m3 0} {$m3 < $count} {incr m3} {                           
				if {1}  {                     
				    set dissigma [expr $sigma*(1+tanh(($gridv($m1-$m3)-$a)/$b))/2.0]                               
				} 
				set disRbin [expr $dl/($dissigma*($S*$bin/$bingrid))]   ;#you should consider $bin here for different conditions               
				set opdisRbin [expr 1/$disRbin]    ;#op means opposite
				set opdisR [expr $opdisR+$opdisRbin]     
			    }
			    set disR [expr 1/$opdisR]
			    set opdisR 0.0    ;#reset opdisR to 0
			    set totalR [expr $totalR+$disR]   
			}
			set current [expr $V/$totalR]
			set totalR 0.0  
		    }
		}
	    }
	}
	#puts "$t $current" 
	set t [expr ($k+0.0*$dk)*$dcdfreq*$timestep*1.0e-6]   ;#unit ms 
	#puts "$t $current"
	puts $output "$t $current"
	
	set ::ICBK::test_current $current
	close $file
    }
    #close $file
    close $output
}
