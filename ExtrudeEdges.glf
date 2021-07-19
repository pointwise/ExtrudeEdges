#############################################################################
#
# (C) 2021 Cadence Design Systems, Inc. All rights reserved worldwide.
#
# This sample script is not supported by Cadence Design Systems, Inc.
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
  label $w(Logo) -image [cadenceLogo] -bd 0 -relief flat

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
  set w(Logo)                   $w(FrameLogo).cadencelogo

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
# cadenceLogo: Define Cadence Design Systems logo
###############################################################################
proc cadenceLogo {} {
  set logoData {
R0lGODlhgAAYAPQfAI6MjDEtLlFOT8jHx7e2tv39/RYSE/Pz8+Tj46qoqHl3d+vq62ZjY/n4+NT
T0+gXJ/BhbN3d3fzk5vrJzR4aG3Fubz88PVxZWp2cnIOBgiIeH769vtjX2MLBwSMfIP///yH5BA
EAAB8AIf8LeG1wIGRhdGF4bXD/P3hwYWNrZXQgYmVnaW49Iu+7vyIgaWQ9Ilc1TTBNcENlaGlIe
nJlU3pOVGN6a2M5ZCI/PiA8eDp4bXBtdGEgeG1sbnM6eD0iYWRvYmU6bnM6bWV0YS8iIHg6eG1w
dGs9IkFkb2JlIFhNUCBDb3JlIDUuMC1jMDYxIDY0LjE0MDk0OSwgMjAxMC8xMi8wNy0xMDo1Nzo
wMSAgICAgICAgIj48cmRmOlJERiB4bWxuczpyZGY9Imh0dHA6Ly93d3cudy5vcmcvMTk5OS8wMi
8yMi1yZGYtc3ludGF4LW5zIyI+IDxyZGY6RGVzY3JpcHRpb24gcmY6YWJvdXQ9IiIg/3htbG5zO
nhtcE1NPSJodHRwOi8vbnMuYWRvYmUuY29tL3hhcC8xLjAvbW0vIiB4bWxuczpzdFJlZj0iaHR0
cDovL25zLmFkb2JlLmNvbS94YXAvMS4wL3NUcGUvUmVzb3VyY2VSZWYjIiB4bWxuczp4bXA9Imh
0dHA6Ly9ucy5hZG9iZS5jb20veGFwLzEuMC8iIHhtcE1NOk9yaWdpbmFsRG9jdW1lbnRJRD0idX
VpZDoxMEJEMkEwOThFODExMUREQTBBQzhBN0JCMEIxNUM4NyB4bXBNTTpEb2N1bWVudElEPSJ4b
XAuZGlkOkIxQjg3MzdFOEI4MTFFQjhEMv81ODVDQTZCRURDQzZBIiB4bXBNTTpJbnN0YW5jZUlE
PSJ4bXAuaWQ6QjFCODczNkZFOEI4MTFFQjhEMjU4NUNBNkJFRENDNkEiIHhtcDpDcmVhdG9yVG9
vbD0iQWRvYmUgSWxsdXN0cmF0b3IgQ0MgMjMuMSAoTWFjaW50b3NoKSI+IDx4bXBNTTpEZXJpZW
RGcm9tIHN0UmVmOmluc3RhbmNlSUQ9InhtcC5paWQ6MGE1NjBhMzgtOTJiMi00MjdmLWE4ZmQtM
jQ0NjMzNmNjMWI0IiBzdFJlZjpkb2N1bWVudElEPSJ4bXAuZGlkOjBhNTYwYTM4LTkyYjItNDL/
N2YtYThkLTI0NDYzMzZjYzFiNCIvPiA8L3JkZjpEZXNjcmlwdGlvbj4gPC9yZGY6UkRGPiA8L3g
6eG1wbWV0YT4gPD94cGFja2V0IGVuZD0iciI/PgH//v38+/r5+Pf29fTz8vHw7+7t7Ovp6Ofm5e
Tj4uHg397d3Nva2djX1tXU09LR0M/OzczLysnIx8bFxMPCwcC/vr28u7q5uLe2tbSzsrGwr66tr
KuqqainpqWko6KhoJ+enZybmpmYl5aVlJOSkZCPjo2Mi4qJiIeGhYSDgoGAf359fHt6eXh3dnV0
c3JxcG9ubWxramloZ2ZlZGNiYWBfXl1cW1pZWFdWVlVUU1JRUE9OTUxLSklIR0ZFRENCQUA/Pj0
8Ozo5ODc2NTQzMjEwLy4tLCsqKSgnJiUkIyIhIB8eHRwbGhkYFxYVFBMSERAPDg0MCwoJCAcGBQ
QDAgEAACwAAAAAgAAYAAAF/uAnjmQpTk+qqpLpvnAsz3RdFgOQHPa5/q1a4UAs9I7IZCmCISQwx
wlkSqUGaRsDxbBQer+zhKPSIYCVWQ33zG4PMINc+5j1rOf4ZCHRwSDyNXV3gIQ0BYcmBQ0NRjBD
CwuMhgcIPB0Gdl0xigcNMoegoT2KkpsNB40yDQkWGhoUES57Fga1FAyajhm1Bk2Ygy4RF1seCjw
vAwYBy8wBxjOzHq8OMA4CWwEAqS4LAVoUWwMul7wUah7HsheYrxQBHpkwWeAGagGeLg717eDE6S
4HaPUzYMYFBi211FzYRuJAAAp2AggwIM5ElgwJElyzowAGAUwQL7iCB4wEgnoU/hRgIJnhxUlpA
SxY8ADRQMsXDSxAdHetYIlkNDMAqJngxS47GESZ6DSiwDUNHvDd0KkhQJcIEOMlGkbhJlAK/0a8
NLDhUDdX914A+AWAkaJEOg0U/ZCgXgCGHxbAS4lXxketJcbO/aCgZi4SC34dK9CKoouxFT8cBNz
Q3K2+I/RVxXfAnIE/JTDUBC1k1S/SJATl+ltSxEcKAlJV2ALFBOTMp8f9ihVjLYUKTa8Z6GBCAF
rMN8Y8zPrZYL2oIy5RHrHr1qlOsw0AePwrsj47HFysrYpcBFcF1w8Mk2ti7wUaDRgg1EISNXVwF
lKpdsEAIj9zNAFnW3e4gecCV7Ft/qKTNP0A2Et7AUIj3ysARLDBaC7MRkF+I+x3wzA08SLiTYER
KMJ3BoR3wzUUvLdJAFBtIWIttZEQIwMzfEXNB2PZJ0J1HIrgIQkFILjBkUgSwFuJdnj3i4pEIlg
eY+Bc0AGSRxLg4zsblkcYODiK0KNzUEk1JAkaCkjDbSc+maE5d20i3HY0zDbdh1vQyWNuJkjXnJ
C/HDbCQeTVwOYHKEJJwmR/wlBYi16KMMBOHTnClZpjmpAYUh0GGoyJMxya6KcBlieIj7IsqB0ji
5iwyyu8ZboigKCd2RRVAUTQyBAugToqXDVhwKpUIxzgyoaacILMc5jQEtkIHLCjwQUMkxhnx5I/
seMBta3cKSk7BghQAQMeqMmkY20amA+zHtDiEwl10dRiBcPoacJr0qjx7Ai+yTjQvk31aws92JZ
Q1070mGsSQsS1uYWiJeDrCkGy+CZvnjFEUME7VaFaQAcXCCDyyBYA3NQGIY8ssgU7vqAxjB4EwA
DEIyxggQAsjxDBzRagKtbGaBXclAMMvNNuBaiGAAA7}

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
