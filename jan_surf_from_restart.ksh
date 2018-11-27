#!/bin/ksh
# generate echam initial file jan_surf.nc from a given restart file
#
# needed e.g. for lgm setup of Uwe Mikolajewicz
# The jan_surf-file can afterwards be used to generate a corresponding 
# jsbach initial file.
#                                                                   March 2014
#------------------------------------------------------------------------------
set -e

restart=rerun_21301_U21_echam_33991231
jan_surf=T31GR30_jan_surf_ctrl.nc

vars_in_jan_surf="SLM GEOSP WS SN SLF AZ0 ALB FOREST WSMX FAO GLAC ALAKE OROMEA OROSTD OROSIG OROGAM OROTHE OROPIC OROVAL"

rm -f *.tmp
for var in ${vars_in_jan_surf}; do
  var_lcase=$(echo ${var} | tr "[A-Z]" "[a-z]")
  cdo -s -setvar,${var} -selvar,${var_lcase} ${restart} ${var}.tmp
  # set maximum for snow thickness to 0.4 m
  if [[ ${var} = SN ]]; then
    cdo -s setmisstoc,0.5 -ifthen -ltc,0.5 ${var}.tmp ${var}.tmp ${var}.tmp1
    mv ${var}.tmp1 ${var}.tmp
  fi
done
rm -f ${jan_surf}
cdo -s merge *.tmp ${jan_surf}
rm -f *.tmp
