#!/bin/ksh
#------------------------------------------------------------------------------
# Script to generate a series of jsbach initial files
#   if new versions are needed in the pool directories.
#
# Veronika Gayler
#------------------------------------------------------------------------------
set -e
export interactive_ctrl=1

res_list="T31 T63 T127 T255"  # "T31 T63 T127 T255 05"
tile_list="11"
soil_list="5"
year_list="0000 1700 1850 1950 1976 2005"
fract_list="false"            # "true false"

for res in ${res_list}; do

  [[ ${res} = T31 ]]  && res_oce_list="GR30"
  [[ ${res} = T63 ]]  && res_oce_list="GR15 TP04 dCRUNCEP"
  [[ ${res} = T127 ]] && res_oce_list="TP04 TP6M"
  [[ ${res} = T255 ]] && res_oce_list="TP04 TP6M"
  [[ ${res} = 05 ]]   && res_oce_list="-"
  
  case ${res} in
    T127 ) years="1850 1950 1976 2005"      ;;
    T255 ) years="1850 1950 1976 2005"      ;;
    * )    years=${year_list}               ;;
  esac

  case ${res} in
#vg     T31 ) dynveg_list="true false" ;;
#vg     T63 ) dynveg_list="true false" ;;
    * )   dynveg_list="false"      ;;
  esac


  for res_oce in ${res_oce_list}; do
    [[ ${res_oce} = - ]] && res_oce=""
    [[ ${res_oce} = dCRUNCEP ]] && fract_list="false"
    for ntiles in ${tile_list}; do
      for nsoil in ${soil_list}; do
        for year in ${years}; do
          for fractional in ${fract_list}; do
            for dynveg in ${dynveg_list}; do
        
              export res_atm=${res}
              export res_oce=${res_oce}
              export ntiles=${ntiles}

              export dynveg=${dynveg}
              export c3c4crop=true
              export lpasture=true
              export read_pasture=LUH2v2h
              export pasture_rule=true

	      if [[ ${year} = 0000 ]]; then  # only natural vegetation
                export dynveg=true
                export read_pasture=false
                export pasture_rule=false
              fi

              export year_cf=${year}
              export year_ct=${year}
              export landcover_series=false 

              export echam_fractional=${fractional}
              export masks_file=default

              export pool_land=/pool/data/JSBACH/prepare/${res_atm}
              if [[ ${res} = 05 ]]; then 
                export pool=/pool/data/JSBACH/05/ECHAM6
              elif [[ ${res_oce} = dCRUNCEP ]]; then
                export pool=${pool_land}/ECHAM6
              elif [[ ${res} = T127 && ${res_oce} = TP6M ]]; then
                export pool=${pool_land}/ECHAM6
              elif [[ ${res} = T255 && ${res_oce} = TP04 ]]; then
                export pool=${pool_land}/ECHAM6
              else
                export pool=/pool/data/ECHAM6/input/r0006/${res_atm}
              fi
              export srcdir=.

              ./jsbach_init_file.ksh

              [[ -d to_pool ]] || mkdir to_pool
              [[ ${dynveg} = true ]] && dynveg_tag="${year}_dynveg" || dynveg_tag="${year}_no-dynveg"
	      [[ ${year} = 0000 ]]   && dynveg_tag="natural-veg"
              if [[ ${fractional} = true ]]; then
                mv jsbach_${res}${res_oce}_fractional_${ntiles}tiles_${nsoil}layers_${dynveg_tag}.nc to_pool
              else
                mv jsbach_${res}${res_oce}_${ntiles}tiles_${nsoil}layers_${dynveg_tag}.nc to_pool
              fi

            done
          done
        done
      done
    done
  done
done

exit 0
