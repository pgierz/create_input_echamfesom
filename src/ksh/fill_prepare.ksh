#!/bin/ksh
#-------------------------------------------------------------------------------
# move data that is used to generate the jsbach initial files from 
# /pool/data/JSBACH/<res> to new directories /pool/data/JSBACH/prepare/<res>.
#
# The intention is to clean up the jsbach pool directories. All files 
# should be either in 
#    perpare: files needed for initial file generation   or in
#    input:   versioned jsbach initial files
#                                                     Veronika Gayler, Mai 2014
#-------------------------------------------------------------------------------
set -e

res_list="T21 T31 T42 T63 T85 T106 T127 T159 T255 T319 05 HD"

jsbach_pool=/pool/data/JSBACH

cd ${jsbach_pool}
[[ -d prepare ]] || mkdir prepare
for res in ${res_list}; do
  [[ -d prepare/${res} ]] || mkdir prepare/${res}
  if [[ ${res} = 05 || ${res} = HD ]]; then
    resg=${res}
  else
    resg=${res}gauss
  fi

  file_list="${res}_topo_75.lola C3C4_crop_${res}.nc C3C4_mask_${resg}.nc LUH_states_${res}.nc LUH_states_${res}.nc.gz albedo_${res}.lola potveg_${res}.nc roughness_length_oro.nc soil_parameters_${res}.nc vegmax_6_${res}.lola vegtype_0_${resg}_pa14.nc vegtype_1850_${resg}_pa14.nc vegtype_1976_${resg}_pa14.nc vegtype_1992_${resg}_pa14.nc vegtype_800_${resg}_pa14.nc vegtype_850_${resg}_pa14.nc 5soillayers_${res}.nc"

  for file in ${file_list}; do
    if [[ -f ${res}/${file} && ! -L ${res}/${file} ]]; then
      mv ${res}/${file} prepare/${res}/${file}
      ln -s ${jsbach_pool}/prepare/${res}/${file} ${res}/${file}
    fi
  done
done

