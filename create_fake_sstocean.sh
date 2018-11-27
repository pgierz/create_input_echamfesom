#!/bin/bash -xe 

#the script creates fake couple restart files based on an existing mpiom restart file ; CO2TRAOC and CO2OCEAN are set constant



#GR30  
mpiom_restart=/pool/data/COSMOS/easyms13/experiments/hel0000/restart/mpiom/rerun_hel0000_mpiom_41851231-18491231.nc

idx1=2
idx2=121
idy1=1
idy2=101

#GR15
#mpiom_restart=
#idx1=2
#idx2=255
#idy1=1
#idy2=220


#TP04
#mpiom_restart=
#idx1=2
#idx2=801
#idy1=3
#idy2=404


cdo -selindexbox,$idx1,$idx2,$idy1,$idy2 -addc,273.15 -setunit,K -setname,SSTOCEAN -selcode,2 -sellevidx,1 $mpiom_restart oo
ncks -O -x -v lat,lon oo ooo
ncwa -O -a time,depth_2 ooo oooo
ncks -O -x -v time,depth_2 oooo sstoce1

cdo -selindexbox,$idx1,$idx2,$idy1,$idy2 -setname,SITOCEAN -selcode,13  $mpiom_restart oo
ncks -O -x -v lat,lon oo ooo 
ncwa -O -a time,depth ooo oooo
ncks -O -x -v time,depth oooo sstoce2

cdo -selindexbox,$idx1,$idx2,$idy1,$idy2 -setname,SICOCEAN -selcode,15  $mpiom_restart oo
ncks -O -x -v lat,lon oo ooo 
ncwa -O -a time,depth ooo oooo
ncks -O -x -v time,depth oooo sstoce3

cdo -selindexbox,$idx1,$idx2,$idy1,$idy2 -setname,SNTOCEAN -selcode,141 $mpiom_restart oo
ncks -O -x -v lat,lon oo ooo 
ncwa -O -a time,depth ooo oooo
ncks -O -x -v time,depth oooo sstoce4

cdo -selindexbox,$idx1,$idx2,$idy1,$idy2 -setname,OCUOCEAN -selcode,3 -sellevidx,1 $mpiom_restart oo
ncks -O -x -v lat_2,lon_2 oo ooo 
ncwa -O -a time,depth_2 ooo oooo
ncks -O -x -v time,depth_2 oooo sstoce5

cdo -selindexbox,$idx1,$idx2,$idy1,$idy2 -setname,OCVOCEAN -selcode,4 -sellevidx,1 $mpiom_restart oo
ncks -O -x -v lat_3,lon_3 oo ooo 
ncwa -O -a time,depth_2 ooo oooo
ncks -O -x -v time,depth_2 oooo sstoce6

# these two are fakes, but should do for the first coupling step
cdo -selindexbox,$idx1,$idx2,$idy1,$idy2 -setname,CO2TRAOC -addc,3.0e-14 -mulc,0 -selcode,2 -sellevidx,1 $mpiom_restart oo
ncks -O -x -v lat,lon oo ooo 
ncwa -O -a time,depth_2 ooo oooo
ncks -O -x -v time,depth_2 oooo sstoce7

cdo -selindexbox,$idx1,$idx2,$idy1,$idy2 -setname,CO2OCEAN -addc,278 -mulc,0 -selcode,2 -sellevidx,1 $mpiom_restart oo
ncks -O -x -v lat,lon oo ooo
ncwa -O -a time,depth_2 ooo oooo
ncks -O -x -v time,depth_2 oooo sstoce8

tar cvf sstocean.tar sstoce? 
\rm oo ooo oooo
