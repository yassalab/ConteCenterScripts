#!/bin/bash
###################################################################################################
##########################              CONTE Center 2.0                 ##########################
##########################              Robert Jirsaraie                 ##########################
##########################              rjirsara@uci.edu                 ##########################
###################################################################################################
#####  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  #####
###################################################################################################
<<Use

This script uses software from optseq2 to create a rapid-presentation event rate for trails of the 
Doors Guessing Task. The aim is to define the optimal timing of events that will allow for varying
amounts of overlap between each trail to better track the hemodynamic responce function.

Use
###################################################################################################
#####  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  #####
###################################################################################################

module load afni/v19.0.01

/dfs2/yassalab/rjirsara/ConteCenter/ConteCenterScripts/fMRItasks/Conte-Two/optseq2 --ntp 110 --tr 2 \
--psdwin 0 20 0.5 --ev WIN 6 13 --ev LOSS 6 13 --tprescan -6 --evc 1 -1 --nkeep 6 --o \
/dfs2/yassalab/rjirsara/ConteCenter/ConteCenterScripts/fMRItasks/Conte-Two/JitterDoorsTask/Doors \
--tnullmin 1.5 --tnullmax 3.5 --nsearch 500000

###################################################################################################
#####  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  ⚡  #####
###################################################################################################
