#!/bin/bash

# the script creates fake coupler restart files with all fluxes set to zero

atm_res=t31grid
cdo -f nc -setname,TXWATMOU -const,0,$atm_res  flxatm9
cdo -f nc -setname,TYWATMOU -const,0,$atm_res  flxatm11
cdo -f nc -setname,TXIATMOU -const,0,$atm_res  flxatm13
cdo -f nc -setname,TYIATMOU -const,0,$atm_res  flxatm15
cdo -f nc -setname,FRIATMOS -const,0,$atm_res  flxatm17

cdo -f nc -setname,FRWATMOS -const,0,$atm_res  flxatm18
cdo -f nc -setname,RHIATMOS -const,0,$atm_res  flxatm19
cdo -f nc -setname,CHIATMOS -const,0,$atm_res  flxatm20
cdo -f nc -setname,NHWATMOS -const,0,$atm_res  flxatm21
cdo -f nc -setname,SHWATMOS -const,0,$atm_res  flxatm22
cdo -f nc -setname,WSVATMOS -const,0,$atm_res  flxatm23
cdo -f nc -setname,CO2CONAT -const,0,$atm_res  flxatm24
cdo -f nc -setname,CO2FLXAT -const,0,$atm_res  flxatm25


tar cvf flxatmos.tar flxatm? flxatm??
