#!/bin/ksh
#------------------------------------------------------------------------------
#
# Generate initial and restart data tarfiles for the different cosmos models
#     cosmos-asob, cosmos-aso, cosmos-as, cosmos-s, cosmos-ob and cosmos-o
#
# Veronika Gayler, January 19th 2010
#------------------------------------------------------------------------------
set -e

# coupled model configurations
cplmod_list="cosmos-asob cosmos-aso cosmos-as cosmos-ob cosmos-o"
tag=""                            # tag for the tarfile name

res_atm=T63                       # atmosphere horizontal resolution
vres_atm=L47                      # atmosphrere vertical resolution
res_oce=TP04                      # ocean horizontal resolution
vres_oce=L80                      # ocean vertical resolution

tarfile_dir=$WRKSHR/pool          # directory in which tarfile will be placed
#vg tarfile_dir=/pool/data/COSMOS/cmip5
wrkdir=$WRKSHR/work.$$            # working directory
set_group_rights=true             # set access rights for the whole group 
group=ik0555                      # unix group

pool_atm=/pool/data/ECHAM6        # pool with echam6 data
pool_srf=/pool/data/JSBACH        # pool with jsbach data
pool_oce=/pool/data/MPIOM         # pool with mpiom data
pool_bgc=/pool/data/MPIOM         # pool with hamocc data
pool_cpl=/pool/data/COSMOS/OASIS3 # pool with oasis3 data

# Restart file directories: "" for no restart files
restart_dir_atm="" # /scratch/k/k204196/cosmos-dev/experiments/vga0042/restart/echam6
restart_dir_srf="" # /scratch/k/k204196/cosmos-dev/experiments/vga0042/restart/jsbach
restart_dir_oce=/work/ik0555/m211054/projects/cosmos-dev/experiments/hel0142/restart/mpiom
restart_dir_bgc=/work/ik0555/m211054/projects/cosmos-dev/experiments/hel0142/restart/hamocc
restart_dir_cpl="" # /scratch/k/k204196/cosmos-dev/experiments/vga0042/restart/oasis3

restart_expid=hel0142             # experiment the restart files come from
restart_date=1949-12-31           # original date of the restart files
new_restart_date=1849-12-31       # date of restart files in the tarfile

# Parameters needed to set new date in echam restart files
fdate=18471231      # date of the initialisation (two years ahead)
vdate=18491231      # restart date (as new_date, different notation)
ndays=731           # number of days since initialisation

#------------------------------------------------------------------------------

ncdump=/sw/aix53/netcdf-4.0.1-ibm/bin/ncdump    # path for blizzard

#------------------------------------------------------------------------------
for cplmod in ${cplmod_list}; do

#
# model components
#
echam6=false; jsbach=false; mpiom=false; hamocc=false; oasis3=false
[[ $(echo ${cplmod} | cut -f2 -d- | grep a) != "" ]]          && echam6=true
[[ $(echo ${cplmod} | cut -f2 -d- | grep s) != "" ]]          && jsbach=true
[[ $(echo ${cplmod} | cut -f2 -d- | grep o) != "" ]]          && mpiom=true
[[ $(echo ${cplmod} | cut -f2 -d- | grep b) != "" ]]          && hamocc=true
[[ $(echo ${cplmod} | cut -f2 -d- | grep a | grep o) != "" ]] && oasis3=true

#
# working directory
#
mkdir ${wrkdir}
cd ${wrkdir}
mkdir input
[[ ${echam6} = true ]] && mkdir input/echam6
[[ ${jsbach} = true ]] && mkdir input/jsbach
[[ ${mpiom}  = true ]] && mkdir input/mpiom
[[ ${hamocc} = true ]] && mkdir input/hamocc
[[ ${oasis3} = true ]] && mkdir input/oasis3

#------------------------------------------------------------------------------
# echam data
#------------------------------------------------------------------------------

if [[ ${echam6} = true ]]; then
  cd input/echam6

  cp -p ${pool_atm}/${res_atm}/${res_atm}${res_oce}_VGRATCLIM.nc      .
  cp -p ${pool_atm}/${res_atm}/${res_atm}${res_oce}_VLTCLIM.nc        .
  cp -p ${pool_atm}/${res_atm}/${res_atm}${res_oce}_jan_surf.nc       .
  cp -p ${pool_atm}/${res_atm}/${res_atm}${vres_atm}_jan_spec.nc      .

  cp -p ${pool_atm}/${res_atm}/${res_atm}_TSLCLIM2.nc                 .
  cp -p ${pool_atm}/${res_atm}/${res_atm}_O3clim2.nc                  .
  cp -p ${pool_atm}/${res_atm}/${res_atm}_OZONE_cmip5_clim.nc         .
  cp -p ${pool_atm}/${res_atm}/${res_atm}_OZONE_cmip5_clim_praeind.nc .

  cp -p ${pool_atm}/surrta_data                                       .
  cp -p ${pool_atm}/hdpara.nc                                         .
  cp -p ${pool_atm}/hdstart.nc                                        .
  cp -p ${pool_atm}/rrtmg_lw.nc                                       .
  cp -p ${pool_atm}/ECHAM6_CldOptProps.nc                             .

  if [[ ${mpiom} != true ]]; then
    cp -p ${pool_atm}/${res_atm}/amip2/${res_atm}_amip2sic_clim.nc    .
    cp -p ${pool_atm}/${res_atm}/amip2/${res_atm}_amip2sst_clim.nc    .
  fi

  cd ../../
fi

#------------------------------------------------------------------------------
# jsbach data
#------------------------------------------------------------------------------

if [[ ${jsbach} = true ]]; then
  cd input/jsbach

  cp -p ${pool_srf}/${res_atm}/jsbach_${res_atm}${res_oce}_4tiles_800.nc    .
  cp -p ${pool_srf}/${res_atm}/jsbach_${res_atm}${res_oce}_11tiles_1850.nc  .
  cp -p ${pool_srf}/${res_atm}/jsbach_${res_atm}${res_oce}_12tiles_1850.nc  .
  cp -p ${pool_srf}/${res_atm}/jsbach_${res_atm}${res_oce}_8tiles_800.nc    .
  cp -p ${pool_srf}/${res_atm}/jsbach_${res_atm}${res_oce}_4tiles_1992.nc   .
  cp -p ${pool_srf}/${res_atm}/jsbach_${res_atm}${res_oce}_11tiles_1992.nc  .
  cp -p ${pool_srf}/${res_atm}/jsbach_${res_atm}${res_oce}_12tiles_1992.nc  .

  if [[ ${echam6} != true ]]; then
    if [[ ${res_atm} != T31 ]]; then
      echo "no climate data file for jsbach available in ${res_atm}"
      exit 1
    fi
    cp -p ${pool_srf}/${res_atm}/Climate_${res_atm}.nc .       
  fi
  cd ../../
fi

#------------------------------------------------------------------------------
# mpiom data
#------------------------------------------------------------------------------

if [[ ${mpiom} = true ]]; then
  cd input/mpiom

  cp -p ${pool_oce}/${res_oce}/${res_oce}${vres_oce}_INISAL_PHC  .
  cp -p ${pool_oce}/${res_oce}/${res_oce}${vres_oce}_INITEM_PHC  .
  cp -p ${pool_oce}/${res_oce}/${res_oce}${vres_oce}_SURSAL_PHC  .

  cp -p ${pool_oce}/${res_oce}/${res_oce}_BEK                    .
  cp -p ${pool_oce}/${res_oce}/${res_oce}_anta                   .
  cp -p ${pool_oce}/${res_oce}/${res_oce}_arcgri                 .
  cp -p ${pool_oce}/${res_oce}/${res_oce}_topo                   .
  cp -p ${pool_oce}/${res_oce}/${res_oce}s.nc                    .
  cp -p ${pool_oce}/${res_oce}/${res_oce}u.nc                    .
  cp -p ${pool_oce}/${res_oce}/${res_oce}v.nc                    .

  if [[ ${echam6} != true ]]; then
    cp -p ${pool_oce}/${res_oce}/${res_oce}_GI*_OMIP365          .
    cp -p ${pool_oce}/runoff_pos                                 .
    cp -p ${pool_oce}/runoff_obs                                 .
  fi

  cd ../../
fi

#------------------------------------------------------------------------------
# hamocc data
#------------------------------------------------------------------------------

if [[ ${hamocc} = true ]]; then
  cd input/hamocc

  cp -p ${pool_bgc}/${res_oce}/${res_oce}_INPDUST.nc             .
  cp -p ${pool_bgc}/${res_oce}/${res_oce}_LUODUST.nc             .
  cp -p ${pool_bgc}/${res_oce}/${res_oce}_MAHOWALDDUST.nc        .

  cat >hamocc_sed_level_file <<EOF
zaxistype : depth_below_sea
size      : 12
levels    : 1 4 9 16 25 36 49 64 81 100 121 144
EOF

  cd ../..
fi

#------------------------------------------------------------------------------
# oasis3 data
#------------------------------------------------------------------------------

if [[ ${oasis3} = true ]]; then
  cd input/oasis3

  cp -p ${pool_cpl}/${res_atm}_${res_oce}/input/areas_${res_atm}_${res_oce}_frac.nc .
  cp -p ${pool_cpl}/${res_atm}_${res_oce}/input/grids_${res_atm}_${res_oce}_frac.nc .
  cp -p ${pool_cpl}/${res_atm}_${res_oce}/input/masks_${res_atm}_${res_oce}_frac.nc .
  cp -p ${pool_cpl}/${res_atm}_${res_oce}/input/nweights_${res_atm}_${res_oce}_frac .
  cp -p ${pool_cpl}/${res_atm}_${res_oce}/input/rmp_atml_to_oces_CONSERV_FRACAREA_${res_atm}_${res_oce}.nc .
  cp -p ${pool_cpl}/${res_atm}_${res_oce}/input/rmp_atmo_to_oces_CONSERV_FRACAREA_${res_atm}_${res_oce}.nc .
  cp -p ${pool_cpl}/${res_atm}_${res_oce}/input/rmp_oces_to_atmo_CONSERV_FRACAREA_${res_atm}_${res_oce}.nc .

#vg  cp -p /work/ik0555/m211054/projects/cosmos-dev/experiments/hel0128/input/oasis3/areas_${res_atm}_${res_oce}_frac.nc .
#vg  cp -p /work/ik0555/m211054/projects/cosmos-dev/experiments/hel0128/input/oasis3/grids_${res_atm}_${res_oce}_frac.nc .
#vg  cp -p /work/ik0555/m211054/projects/cosmos-dev/experiments/hel0128/input/oasis3/masks_${res_atm}_${res_oce}_frac.nc .
#vg  cp -p /work/ik0555/m211054/projects/cosmos-dev/experiments/hel0128/input/oasis3/nweights_${res_atm}_${res_oce}_frac .
#vg  cp -p /work/ik0555/m211054/projects/cosmos-dev/experiments/hel0128/input/oasis3/rmp_atml_to_oces_CONSERV_FRACAREA_${res_atm}_${res_oce}.nc .
#vg  cp -p /work/ik0555/m211054/projects/cosmos-dev/experiments/hel0128/input/oasis3/rmp_atmo_to_oces_CONSERV_FRACAREA_${res_atm}_${res_oce}.nc .
#vg  cp -p /work/ik0555/m211054/projects/cosmos-dev/experiments/hel0128/input/oasis3/rmp_oces_to_atmo_CONSERV_FRACAREA_${res_atm}_${res_oce}.nc .
  cd ../..
fi

#------------------------------------------------------------------------------
# restart data
#------------------------------------------------------------------------------

restdate=$(echo ${restart_date} | tr -d -)
if [[ ${echam6} = true && ${restart_dir_atm} != "" ]]; then
  mkdir -p restart/echam6
  # nstep = nsteps_per_day * nday - 1
  
  timestep=$(${ncdump} -h ${restart_dir_atm}/rerun_${restart_expid}_echam_${restdate} \
            | grep :timestep | cut -f3 -d' ' | cut -f1 -d.)
  (( nstep = 86400 / timestep * ndays - 1 ))
  ncatted -a fdate,global,m,i,${fdate} -a vdate,global,m,i,${vdate} \
          -a nstep,global,m,i,${nstep} \
          ${restart_dir_atm}/rerun_${restart_expid}_echam_${restdate} \
          restart/echam6/rerun_echam.nc
  if [[ ${mpiom} = true ]]; then
    cp -p ${restart_dir_atm}/hdrestart_${restart_expid}_${restdate}.nc \
          restart/echam6/hdrestart.nc
  fi
  if [[ -f ${restart_dir_atm}/rerun_${restart_expid}_co2_${restdate} ]]; then
    cp -p ${restart_dir_atm}/rerun_${restart_expid}_co2_${restdate} \
          restart/echam6/rerun_co2.nc
#vg     cp -p ${restart_dir_atm}/rerun_${restart_expid}_tracer_${restdate} \
#vg           restart/echam6/rerun_tracer.nc
  fi
fi

if [[  ${jsbach} = true && ${restart_dir_srf} != "" ]]; then
  mkdir -p restart/jsbach
  cp -p ${restart_dir_srf}/rerun_${restart_expid}_jsbach_${restdate} \
          restart/jsbach/rerun_jsbach.nc
  cp -p ${restart_dir_srf}/rerun_${restart_expid}_veg_${restdate} \
          restart/jsbach/rerun_veg.nc
  if [[ ${echam6} = true ]]; then
    cp -p ${restart_dir_srf}/rerun_${restart_expid}_surf_${restdate} \
          restart/jsbach/rerun_surf.nc
  else
    cp -p ${restart_dir_srf}/rerun_${restart_expid}_forcing_${restdate} \
          restart/jsbach/rerun_forcing.nc
    cp -p ${restart_dir_srf}/rerun_${restart_expid}_driving_${restdate} \
          restart/jsbach/rerun_driving.nc
  fi
fi

if [[  ${mpiom} = true && ${restart_dir_oce} != "" ]]; then
  mkdir -p restart/mpiom
  cdo setdate,${new_restart_date} \
          ${restart_dir_oce}/rerun_${restart_expid}_mpiom_${restdate}.nc \
          restart/mpiom/rerun_mpiom.nc
fi

if [[ ${hamocc} = true && ${restart_dir_bgc} != "" ]]; then
  mkdir -p restart/hamocc
  cdo setdate,${new_restart_date} \
          ${restart_dir_bgc}/rerun_${restart_expid}_hamocc_${restdate}.nc \
          restart/hamocc/rerun_hamocc.nc
fi

if [[ ${oasis3} = true && ${restart_dir_cpl} != "" ]]; then
  mkdir -p restart/oasis3
  cp -p ${restart_dir_cpl}/sstocean_${restart_expid}_${restdate}.tar \
          restart/oasis3/sstocean.tar
  cp -p ${restart_dir_cpl}/flxatmos_${restart_expid}_${restdate}.tar \
          restart/oasis3/flxatmos.tar
fi

#------------------------------------------------------------------------------
# generate the tarfile
#------------------------------------------------------------------------------

[[ -d ${tarfile_dir}/${cplmod} ]] || mkdir -p ${tarfile_dir}/${cplmod}
if [[ ${oasis3} = true ]]; then
  tarfile=${tarfile_dir}/${cplmod}/input_${cplmod}_${res_atm}${vres_atm}_${res_oce}${vres_oce}${tag}.tar
elif [[ ${mpiom} = true ]]; then
  tarfile=${tarfile_dir}/${cplmod}/input_${cplmod}_${res_oce}${vres_oce}${tag}.tar
elif [[ ${echam6} = true ]]; then
  tarfile=${tarfile_dir}/${cplmod}/input_${cplmod}_${res_atm}${vres_atm}_${res_oce}${tag}.tar
else
  tarfile=${tarfile_dir}/${cplmod}/input_${cplmod}_${res_atm}${tag}.tar
fi

if [[ -f ${tarfile} ]]; then
  mv ${tarfile} ${tarfile}_$(ls -l ${tarfile} | cut -f6 -d' ')
fi

userid=`whoami`
cat > README <<EOF

Tarfile with initial (and restart) data for ${cplmod}
   generated by ${userid}, `date`
EOF

if [[ -d restart ]]; then
cat >> README <<EOF

!!! Preliminary restart files !!!
  --> tarfile should be used only for testing and NOT for production

source :: restart files from experiment ${restart_expid} - date: ${restart_date}
          Date changed to ${new_restart_date}
EOF
fi

if [[ ! -d restart ]]; then
  tar cvf ${tarfile} input README
else
  tar cvf ${tarfile} input restart README
fi
if [[ ${set_group_rights} = true ]]; then
  chgrp ${group} ${tarfile}
  chmod 775 ${tarfile}
fi

# clean up
cd ..
rm -rf ${wrkdir}

done  # loop over coupled models
