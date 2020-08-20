#!/bin/ksh
#------------------------------------------------------------------------------
#
# prepare restart data for the different cosmos models
#     cosmos-asob, cosmos-aso, cosmos-as, cosmos-s, cosmos-ob and cosmos-o
#
#------------------------------------------------------------------------------
set -ex

# coupled model configurations
cplmod_list="cosmos-asob"
# cosmos-aso cosmos-as cosmos-ob cosmos-o"
tag=""                            # tag for the tarfile name

res_atm=T31                       # atmosphere horizontal resolution
vres_atm=L31                      # atmosphrere vertical resolution
res_oce=GR30                      # ocean horizontal resolution
vres_oce=L40                      # ocean vertical resolution

wrkdir=$WRKSHR/pool          # directory in which tarfile will be placed
set_group_rights=true             # set access rights for the whole group 
group=mh0469                      # unix group


# Restart file directories: "" for no restart files
restart_dir_atm=/work/mh0469/m211054/projects/easyms14/mpiesm-easyms13/experiments/sus1400/restart/echam6
restart_dir_srf=/work/mh0469/m211054/projects/easyms14/mpiesm-easyms13/experiments/sus1400/restart/jsbach
restart_dir_oce=/work/mh0469/m211054/projects/easyms14/mpiesm-easyms13/experiments/sus1400/restart/mpiom
restart_dir_bgc=/work/mh0469/m211054/projects/easyms14/mpiesm-easyms13/experiments/sus1400/restart/hamocc
restart_dir_cpl=/work/mh0469/m211054/projects/easyms14/mpiesm-easyms13/experiments/sus1400/restart/oasis3mct

restart_expid=sus1400             # experiment the restart files come from
restart_date=2361-12-31           # original date of the restart files
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
echam6=false; jsbach=false; mpiom=false; hamocc=false; oasis3mct=false
[[ $(echo ${cplmod} | cut -f2 -d- | grep a) != "" ]]          && echam6=true
[[ $(echo ${cplmod} | cut -f2 -d- | grep s) != "" ]]          && jsbach=true
[[ $(echo ${cplmod} | cut -f2 -d- | grep o) != "" ]]          && mpiom=true
[[ $(echo ${cplmod} | cut -f2 -d- | grep b) != "" ]]          && hamocc=true
[[ $(echo ${cplmod} | cut -f2 -d- | grep a | grep o) != "" ]] && oasis3mct=true

#
# working directory
#
mkdir -p ${wrkdir}
cd ${wrkdir}
#------------------------------------------------------------------------------
# restart data
#------------------------------------------------------------------------------

restdate=$(echo ${restart_date} | tr -d -)
newresdate=$(echo ${new_restart_date} | tr -d -)
if [[ ${echam6} = true && ${restart_dir_atm} != "" ]]; then
  mkdir -p restart/echam6
  # nstep = nsteps_per_day * nday - 1
  
  timestep=$(${ncdump} -h ${restart_dir_atm}/restart_${restart_expid}_echam_${restdate}.nc \
            | grep :timestep | cut -f3 -d' ' | cut -f1 -d.)
  (( nstep = 86400 / timestep * ndays - 1 ))
  ncatted -a fdate,global,m,i,${fdate} -a vdate,global,m,i,${vdate} \
          -a nstep,global,m,i,${nstep} \
          ${restart_dir_atm}/restart_${restart_expid}_echam_${restdate}.nc \
          restart/echam6/restart_${restart_expid}_echam_${restdate}-${newresdate}.nc
  if [[ ${mpiom} = true ]]; then
    cp -p ${restart_dir_atm}/restart_${restart_expid}_hd_${restdate}.nc \
          restart/echam6/restart_${restart_expid}_hd_${restdate}-${newresdate}.nc
  fi
  if [[ -f ${restart_dir_atm}/restart_${restart_expid}_co2_${restdate}.nc ]]; then
    cp -p ${restart_dir_atm}/restart_${restart_expid}_co2_${restdate}.nc \
          restart/echam6/restart_${restart_expid}_co2_${restdate}-${newresdate}.nc
  fi
  if [[ -f ${restart_dir_atm}/restart_${restart_expid}_tracer_${restdate}.nc ]]; then
    cp -p ${restart_dir_atm}/restart_${restart_expid}_tracer_${restdate}.nc \
          restart/echam6/restart_${restart_expid}_tracer_${restdate}-${newresdate}.nc
  fi
fi

if [[  ${jsbach} = true && ${restart_dir_srf} != "" ]]; then
  mkdir -p restart/jsbach
  cp -p ${restart_dir_srf}/restart_${restart_expid}_jsbach_${restdate}.nc \
          restart/jsbach/restart_${restart_expid}_jsbach_${restdate}-${newresdate}.nc
  cp -p ${restart_dir_srf}/restart_${restart_expid}_veg_${restdate}.nc \
          restart/jsbach/restart_${restart_expid}_veg_${restdate}-${newresdate}.nc
  if [[ ${echam6} = true ]]; then
    cp -p ${restart_dir_srf}/restart_${restart_expid}_surf_${restdate}.nc \
          restart/jsbach/restart_${restart_expid}_surf_${restdate}-${newresdate}.nc
  else
    cp -p ${restart_dir_srf}/restart_${restart_expid}_forcing_${restdate}.nc \
          restart/jsbach/restart_${restart_expid}_forcing_${restdate}-${newresdate}.nc
    cp -p ${restart_dir_srf}/restart_${restart_expid}_driving_${restdate}.nc \
          restart/jsbach/restart_${restart_expid}_driving_${restdate}-${newresdate}.nc
  fi
fi

if [[  ${mpiom} = true && ${restart_dir_oce} != "" ]]; then
  mkdir -p restart/mpiom
  cdo setdate,${new_restart_date} \
          ${restart_dir_oce}/rerun_${restart_expid}_mpiom_${restdate}.nc \
          restart/mpiom/rerun_${restart_expid}_mpiom_${restdate}-${newresdate}.nc
fi

if [[ ${hamocc} = true && ${restart_dir_bgc} != "" ]]; then
  mkdir -p restart/hamocc
  cdo setdate,${new_restart_date} \
          ${restart_dir_bgc}/rerun_${restart_expid}_hamocc_${restdate}.nc \
          restart/hamocc/rerun_${restart_expid}_hamocc_${restdate}-${newresdate}.nc
fi

if [[ ${oasis3mct} = true && ${restart_dir_cpl} != "" ]]; then
  mkdir -p restart/oasis3mct
  cp -p ${restart_dir_cpl}/sstocean_${restart_expid}_${restdate}.tar \
          restart/oasis3mct/sstocean_${restart_expid}_${restdate}-${newresdate}.tar
  cp -p ${restart_dir_cpl}/flxatmos_${restart_expid}_${restdate}.tar \
          restart/oasis3mct/flxatmos_${restart_expid}_${restdate}-${newresdate}.tar
fi

done  # loop over coupled models
