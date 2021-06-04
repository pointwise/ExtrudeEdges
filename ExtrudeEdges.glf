#############################################################################
#
# (C) 2021 Cadence Design Systems, Inc. All rights reserved worldwide.
#
# This sample source code is not supported by Cadence Design Systems, Inc.
# It is provided freely for demonstration purposes only.
# SEE THE WARRANTY DISCLAIMER AT THE BOTTOM OF THIS FILE.
#
#############################################################################
# Written by J. Rhoads, 7/7/2014
# ==============================================================================
# Create extrusion of edges for trimming operations
# ==============================================================================
# This script prompts the user to select a quilt. An extrusion is then created 
# from the edges of this quilt, assembled into a model, and layered into 
# layer 999 for easy tracking. This operation can be very useful when trying to 
# trim with a surface that doesn't intersect nicely.
#
#############################################################################

package require PWI_Glyph 2.3
pw::Script loadTk

proc ExtrudeEdges { } {
    global input curSelection
    
    wm withdraw .
    
    set vec [pwu::Vector3 scale [pwu::Vector3 normalize $input(norm)] $input(dS)]

    # If there was a valid quilt selected when script starts then don't do this section
    # curSelection is already populated from retrieveQuilts proc
    if { ! [array exists curSelection] ||
           [llength [array get curSelection Databases]] == 0 ||
           [llength $curSelection(Databases)] == 0 } {
        ## Selection of quilt
        set text1 "Please select Quilt to extrude."
        set mask [pw::Display createSelectionMask -requireDatabase {Quilts}]

        set picked [pw::Display selectEntities -description $text1 \
            -selectionmask $mask -single curSelection]
        if {!$picked} {exit}
    }
    
    set surfs [list]

    ## Get initial layer states
    catch { pw::Layer removeState _extrudeEdgesState }
    pw::Layer saveState _extrudeEdgesState

    ## Change layer to 999 to contain all created entites
    pw::Display isolateLayer 999

    ## Loop through quilts to get edges and create surfaces
    set quilts $curSelection(Databases)
    foreach qq $quilts {
        set N [$qq getBoundaryCount]
        for { set ii 1 } { $ii <= $N } {incr ii} {
            set edge [$qq getBoundary $ii]
            set tmp1 [pw::Surface create]
            if { ! [catch {$tmp1 sweep $edge [pwu::Vector3 scale $vec 1]}] } {
              lappend surfs [list $tmp1]
            }
            set tmp2 [pw::Surface create]
            if { ! [catch {$tmp2 sweep $edge [pwu::Vector3 scale $vec -1]}] } {
              lappend surfs [list $tmp2]
            }
        }
    }

    ## Assemble extrusions into model
    set newModel [pw::Model assemble -tolerance 0.01 $surfs]

    ## Restore initial layer state and cleanup, leaving layer 999 visible
    pw::Layer restoreState {_extrudeEdgesState}
    pw::Display showLayer 999
    pw::Layer removeState {_extrudeEdgesState}
    
    exit
}

## Create window
proc makeWindow {} {
  global w input curSelection

  wm title . "Extrude Edges"
  label $w(LabelTitle) -text "Extrusion Parameters:" -padx 10
  setTitleFont $w(LabelTitle)

  frame $w(FrameMain)
  label $w(LabelVector) -text "Normal Vector:" -anchor e
  entry $w(EntryVector) -width 10 -bd 2 -textvariable input(norm)

  label $w(LabelExtent) -text "Distance:" -padx 2 -anchor e
  entry $w(EntryExtent) -width 10 -bd 2 -textvariable input(dS)
  
  if { [array exists curSelection] &&
       [llength [array get curSelection Databases]] == 2 &&
       [llength $curSelection(Databases)] == 1 } {
      # Set text on button to "Run" if there is already a quilt selected
      button $w(ButtonSelect) -text "Run" -command { ExtrudeEdges }
  } else {
      # Set text on button to "Select" if a quilt needs to be selected by the user
      button $w(ButtonSelect) -text "Select" -command { ExtrudeEdges }
  }
  button $w(ButtonCancel) -text "Cancel" -command { destroy . }

  frame $w(FrameLogo) -relief sunken
  label $w(Logo) -image [pwLogo] -bd 0 -relief flat

  # set up validation after all widgets are created so that they all exist when
  # validation fires the first time; if they don't all exist, updateButtons
  # will fail
  $w(EntryVector) configure -validate key -vcmd { validateNorm %P EntryVector }
  $w(EntryExtent) configure -validate key -vcmd { validateAlpha %P EntryExtent }

  # lay out the form
  pack $w(LabelTitle) -side top
  pack [frame .sp -bd 1 -height 2 -relief sunken] -pady 4 -side top -fill x
  pack $w(FrameMain) -side top -fill both -expand 1

  # lay out the form in a grid
  grid $w(LabelVector) -row 1 -column 1 -sticky e -pady 3 -padx 3
  grid $w(EntryVector) -row 1 -column 2 -sticky w -pady 3 -padx 3
  grid $w(LabelExtent) -row 2 -column 1 -sticky e -pady 3 -padx 3
  grid $w(EntryExtent) -row 2 -column 2 -sticky w -pady 3 -padx 3
  grid $w(ButtonSelect) -row 3 -column 1 -pady 3
  grid $w(ButtonCancel) -row 3 -column 2 -pady 3
  grid columnconfigure $w(FrameMain) 1 -weight 1

  # give all extra space to the second (last) column
  grid columnconfigure $w(FrameMain) 1 -weight 1
  grid columnconfigure $w(FrameMain) 2 -weight 1

  pack $w(FrameLogo) -fill x -side bottom -padx 2 -pady 4 -anchor s
  grid $w(Logo) -columnspan 2

  bind . <Key-Escape> { $w(ButtonCancel) invoke }
  bind . <Control-Key-Return> { $w(ButtonSelect) invoke }
  bind . <Control-Key-f> { $w(ButtonSelect) invoke }

}

## Set up defaults for window
set color(Valid)   "white"
set color(Invalid) "misty rose"
    
set input(norm) {1 0 0}
set input(dS) 0.01

set w(LabelTitle)           .title
set w(FrameMain)          .main
  set w(LabelVector)         $w(FrameMain).ldim
  set w(EntryVector)         $w(FrameMain).edim
  set w(LabelExtent)          $w(FrameMain).lext
  set w(EntryExtent)          $w(FrameMain).eext
  set w(ButtonSelect)       $w(FrameMain).select
  set w(ButtonCancel)        $w(FrameMain).bcancel
set w(FrameLogo)      .fbuttons
  set w(Logo)                   $w(FrameLogo).pwlogo

# dimension field validation
proc validateNorm { norm widget } {
  global w color
  set flag 0
  
  if {[llength $norm]==3} {
    foreach dim $norm {
        if { ![string is double -strict $dim] } {
            incr flag
        }
    }
    if {$flag==0} {
        if { [pwu::Vector3 length $norm] > 0 } {
            $w($widget) configure -background $color(Valid)
        } else {
            $w($widget) configure -background $color(Invalid)
        }
    } else {
        $w($widget) configure -background $color(Invalid)
    }
  } else {
      $w($widget) configure -background $color(Invalid)
  }
  updateButtons
  return 1
}

# extent field validation
proc validateAlpha { alpha widget } {
  global w color
  if { [string is double -strict $alpha] && $alpha > 0 } {
    $w($widget) configure -background $color(Valid)
  } else {
    $w($widget) configure -background $color(Invalid)
  }
  updateButtons
  return 1
}

# return true if none of the entry fields are marked invalid
proc canCreate { } {
  global w color
  return [expr \
    [string equal -nocase [$w(EntryVector) cget -background] $color(Valid)] &&\
    [string equal -nocase [$w(EntryExtent) cget -background] $color(Valid)]]
}

# enable/disable action buttons based on current settings
proc updateButtons { } {
  global w infoMessage

  if { [canCreate] } {
    $w(ButtonSelect) configure -state normal
  } else {
    $w(ButtonSelect) configure -state disabled
  }
  update
}

# set the font for the input widget to be bold and 1.5 times larger than
# the default font
proc setTitleFont { l } {
  global titleFont
  if { ! [info exists titleFont] } {
    set fontSize [font actual TkCaptionFont -size]
    set titleFont [font create -family [font actual TkCaptionFont -family] \
        -weight bold -size [expr {int(1.5 * $fontSize)}]]
  }
  $l configure -font $titleFont
}

###############################################################################
# pwLogo: Define pointwise logo
###############################################################################
proc pwLogo {} {
  set logoData {
R0lGODlheAAYAIcAAAAAAAICAgUFBQkJCQwMDBERERUVFRkZGRwcHCEhISYmJisrKy0tLTIyMjQ0
NDk5OT09PUFBQUVFRUpKSk1NTVFRUVRUVFpaWlxcXGBgYGVlZWlpaW1tbXFxcXR0dHp6en5+fgBi
qQNkqQVkqQdnrApmpgpnqgpprA5prBFrrRNtrhZvsBhwrxdxsBlxsSJ2syJ3tCR2siZ5tSh6tix8
ti5+uTF+ujCAuDODvjaDvDuGujiFvT6Fuj2HvTyIvkGKvkWJu0yUv2mQrEOKwEWNwkaPxEiNwUqR
xk6Sw06SxU6Uxk+RyVKTxlCUwFKVxVWUwlWWxlKXyFOVzFWWyFaYyFmYx16bwlmZyVicyF2ayFyb
zF2cyV2cz2GaxGSex2GdymGezGOgzGSgyGWgzmihzWmkz22iymyizGmj0Gqk0m2l0HWqz3asznqn
ynuszXKp0XKq1nWp0Xaq1Hes0Xat1Hmt1Xyt0Huw1Xux2IGBgYWFhYqKio6Ojo6Xn5CQkJWVlZiY
mJycnKCgoKCioqKioqSkpKampqmpqaurq62trbGxsbKysrW1tbi4uLq6ur29vYCu0YixzYOw14G0
1oaz14e114K124O03YWz2Ie12oW13Im10o621Ii22oi23Iy32oq52Y252Y+73ZS51Ze81JC625G7
3JG825K83Je72pW93Zq92Zi/35G+4aC90qG+15bA3ZnA3Z7A2pjA4Z/E4qLA2KDF3qTA2qTE3avF
36zG3rLM3aPF4qfJ5KzJ4LPL5LLM5LTO4rbN5bLR6LTR6LXQ6r3T5L3V6cLCwsTExMbGxsvLy8/P
z9HR0dXV1dbW1tjY2Nra2tzc3N7e3sDW5sHV6cTY6MnZ79De7dTg6dTh69Xi7dbj7tni793m7tXj
8Nbk9tjl9N3m9N/p9eHh4eTk5Obm5ujo6Orq6u3t7e7u7uDp8efs8uXs+Ozv8+3z9vDw8PLy8vL0
9/b29vb5+/f6+/j4+Pn6+/r6+vr6/Pn8/fr8/Pv9/vz8/P7+/gAAACH5BAMAAP8ALAAAAAB4ABgA
AAj/AP8JHEiwoMGDCBMqXMiwocOHECNKnEixosWLGDNqZCioo0dC0Q7Sy2btlitisrjpK4io4yF/
yjzKRIZPIDSZOAUVmubxGUF88Aj2K+TxnKKOhfoJdOSxXEF1OXHCi5fnTx5oBgFo3QogwAalAv1V
yyUqFCtVZ2DZceOOIAKtB/pp4Mo1waN/gOjSJXBugFYJBBflIYhsq4F5DLQSmCcwwVZlBZvppQtt
D6M8gUBknQxA879+kXixwtauXbhheFph6dSmnsC3AOLO5TygWV7OAAj8u6A1QEiBEg4PnA2gw7/E
uRn3M7C1WWTcWqHlScahkJ7NkwnE80dqFiVw/Pz5/xMn7MsZLzUsvXoNVy50C7c56y6s1YPNAAAC
CYxXoLdP5IsJtMBWjDwHHTSJ/AENIHsYJMCDD+K31SPymEFLKNeM880xxXxCxhxoUKFJDNv8A5ts
W0EowFYFBFLAizDGmMA//iAnXAdaLaCUIVtFIBCAjP2Do1YNBCnQMwgkqeSSCEjzzyJ/BFJTQfNU
WSU6/Wk1yChjlJKJLcfEgsoaY0ARigxjgKEFJPec6J5WzFQJDwS9xdPQH1sR4k8DWzXijwRbHfKj
YkFO45dWFoCVUTqMMgrNoQD08ckPsaixBRxPKFEDEbEMAYYTSGQRxzpuEueTQBlshc5A6pjj6pQD
wf9DgFYP+MPHVhKQs2Js9gya3EB7cMWBPwL1A8+xyCYLD7EKQSfEF1uMEcsXTiThQhmszBCGC7G0
QAUT1JS61an/pKrVqsBttYxBxDGjzqxd8abVBwMBOZA/xHUmUDQB9OvvvwGYsxBuCNRSxidOwFCH
J5dMgcYJUKjQCwlahDHEL+JqRa65AKD7D6BarVsQM1tpgK9eAjjpa4D3esBVgdFAB4DAzXImiDY5
vCFHESko4cMKSJwAxhgzFLFDHEUYkzEAG6s6EMgAiFzQA4rBIxldExBkr1AcJzBPzNDRnFCKBpTd
gCD/cKKKDFuYQoQVNhhBBSY9TBHCFVW4UMkuSzf/fe7T6h4kyFZ/+BMBXYpoTahB8yiwlSFgdzXA
5JQPIDZCW1FgkDVxgGKCFCywEUQaKNitRA5UXHGFHN30PRDHHkMtNUHzMAcAA/4gwhUCsB63uEF+
bMVB5BVMtFXWBfljBhhgbCFCEyI4EcIRL4ChRgh36LBJPq6j6nS6ISPkslY0wQbAYIr/ahCeWg2f
ufFaIV8QNpeMMAkVlSyRiRNb0DFCFlu4wSlWYaL2mOp13/tY4A7CL63cRQ9aEYBT0seyfsQjHedg
xAG24ofITaBRIGTW2OJ3EH7o4gtfCIETRBAFEYRgC06YAw3CkIqVdK9cCZRdQgCVAKWYwy/FK4i9
3TYQIboE4BmR6wrABBCUmgFAfgXZRxfs4ARPPCEOZJjCHVxABFAA4R3sic2bmIbAv4EvaglJBACu
IxAMAKARBrFXvrhiAX8kEWVNHOETE+IPbzyBCD8oQRZwwIVOyAAXrgkjijRWxo4BLnwIwUcCJvgP
ZShAUfVa3Bz/EpQ70oWJC2mAKDmwEHYAIxhikAQPeOCLdRTEAhGIQKL0IMoGTGMgIBClA9QxkA3U
0hkKgcy9HHEQDcRyAr0ChAWWucwNMIJZ5KilNGvpADtt5JrYzKY2t8nNbnrzm+B8SEAAADs=}

  return [image create photo -format GIF -data $logoData]
}


################################################################################
# Test if quilts were selected before script starts
################################################################################

pw::Display getSelectedEntities -selectionmask [pw::Display createSelectionMask -requireDatabase {Quilts}] curSelection

makeWindow

tkwait window .
  
#############################################################################
#
# This file is licensed under the Cadence Public License Version 1.0 (the
# "License"), a copy of which is found in the included file named "LICENSE",
# and is distributed "AS IS." TO THE MAXIMUM EXTENT PERMITTED BY APPLICABLE
# LAW, CADENCE DISCLAIMS ALL WARRANTIES AND IN NO EVENT SHALL BE LIABLE TO
# ANY PARTY FOR ANY DAMAGES ARISING OUT OF OR RELATING TO USE OF THIS FILE.
# Please see the License for the full text of applicable terms.
#
#############################################################################
