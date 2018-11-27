#!/bin/ksh
################################################################################
# Script to generate initial data files for different COSMOS configurations
#
# Irina Fast, Summer 2009
#
# Modifications:
#   Veronika Gayler, October 2009 
#          -changes concerning land sea and lake masks
#          -create a variety of jsbach initial files for different purposes
################################################################################
set -e
################################################################################
# switch off interactive mode in the script jsbach_init_file.ksh
export interactive_ctrl=1

# coupled model acronym (as, aso, asob, o, ob etc.)
export cplmod=asob

# component model resolutions
export res_atm=T63         # atmosphere horizontal resolution
export vres_atm=L47        # atmosphrere vertical resolution
export res_oce=TP10        # ocean horizontal resolution
export vres_oce=L40        # ocean vertical resolution

# input data
export pool_atm_standalone=/pool/data/ECHAM5                # pool with atm input data
[[ ${res_atm} = T127 ]] && export pool_atm_standalone=/work/mh0081/prep/echam6
[[ ${res_atm} = T255 ]] && export pool_atm_standalone=/work/im0454/ECHAM6
export pool_atm=/pool/data/ECHAM6
export pool_oce=/pool/data/MPIOM                 # pool with oce input data
export pool_srf=/pool/data/JSBACH                # pool with srf input data
[[ ${res_atm} = T255 ]] && export pool_srf=/work/im0454/JSBACH   # pool with srf input data
export pool_cpl=$WRKSHR/tarfiles           # pool for created input data

# restart data
#restart_mpiom=/work/mh0033/m211054/tp04l80/experiments/tp04l80_halo/restart/Z37000_0467
#restart_hamocc=/work/mh0033/m211054/tp04l80/experiments/tp04l80_halo/restart/tp04l80_halo_restartr_bgc_0467.nc
restart_mpiom=""
restart_hamocc=""

export wrkdir=$WRKSHR/tarfiles/work.$$     # working directory for the tarfile generation  

alias cdo=$(which cdo)

with_lakes=true      # generate echam and jsbach initial files with/without lakes

################################################################################

tarfile=input_cosmos-${cplmod}

#
# script directory
#
export srcdir=$(dirname $0)
cd $srcdir
srcdir=$(pwd)
cd -

#
# working directory
#
[[ -d ${wrkdir} ]] && rm -rf ${wrkdir}
mkdir ${wrkdir}
cd ${wrkdir}

[[ "$(echo ${cplmod} | grep a)" = "${cplmod}" ]] && atminp=yes || atminp=no  
[[ "$(echo ${cplmod} | grep o)" = "${cplmod}" ]] && oceinp=yes || oceinp=no  
[[ "$(echo ${cplmod} | grep s)" = "${cplmod}" ]] && srfinp=yes || srfinp=no  
[[ "$(echo ${cplmod} | grep b)" = "${cplmod}" ]] && bgcinp=yes || bgcinp=no  

[[ "${atminp}" = "yes" ]] && [[ "${oceinp}" = "yes" ]] && lcouple=.true. || lcouple=.false.
export lcouple

#-------------------------------------
# ECHAM input files
#-------------------------------------
if [[ "${atminp}" = "yes" ]]; then

  mkdir -p input/echam6
  cd input/echam6

  if [[ "${lcouple}" = ".true." ]]; then

    # remapping of the ocean land sea mask to the atmosphere grid 
    cdo setmisstoc,1 -remapcon,t${res_atm#T}grid ${pool_oce}/${res_oce}/${res_oce}_lsm.nc ../../echam_lsm.nc

    # adaptation of the echam initial data to the new land sea mask
    cdo change_e5slm,../../echam_lsm.nc ${pool_atm_standalone}/${res_atm}/${res_atm}_VGRATCLIM.nc  ${res_atm}${res_oce}_VGRATCLIM.nc 
    cdo change_e5slm,../../echam_lsm.nc ${pool_atm_standalone}/${res_atm}/${res_atm}_VLTCLIM.nc    ${res_atm}${res_oce}_VLTCLIM.nc
    cdo change_e5slm,../../echam_lsm.nc ${pool_atm_standalone}/${res_atm}/${res_atm}_jan_surf.nc   ${res_atm}${res_oce}_jan_surf.nc

    # adapt the lake mask, add an integer land sea mask and adapt the fractional mask

    AFILE=${pool_atm_standalone}/${res_atm}/${res_atm}_jan_surf.nc
    CFILE=${res_atm}${res_oce}_jan_surf.nc

    # calculate the integer land sea mask

    if [[ ${res_atm} = T31  && ${res_oce} = GR30 ]]; then
      # in T31GR30 land grid cells are added in the tropics, only 
      slm_fraction=0.435
      cdo gec,${slm_fraction} -masklonlatbox,0,360,-30,30 -selvar,SLM ${CFILE} slm.tropic
      cdo gec,0.5 -selvar,SLM ${CFILE} slm.extratr
      cdo setmisstoc,0 -gec,-1 slm.tropic mask
      cdo ifthenelse mask slm.tropic slm.extratr slm
      rm mask slm.extratr slm.tropic
    else
      # target is a global land fraction of 147 Mio km2 
      #   for diagnostics set info=.true. in namelist fot jsbach_init_file
      slm_fraction=0.5    
      [[ ${res_atm} = T31  && ${res_oce} = TP10 ]] && slm_fraction=0.52
      [[ ${res_atm} = T63  && ${res_oce} = TP10 ]] && slm_fraction=0.53
      [[ ${res_atm} = T63  && ${res_oce} = TP04 ]] && slm_fraction=0.52
      [[ ${res_atm} = T63  && ${res_oce} = GR15 ]] && slm_fraction=0.50
      [[ ${res_atm} = T106 && ${res_oce} = TP04 ]] && slm_fraction=0.55
      [[ ${res_atm} = T127 && ${res_oce} = GR15 ]] && slm_fraction=0.54
      [[ ${res_atm} = T127 && ${res_oce} = TP04 ]] && slm_fraction=0.57
      [[ ${res_atm} = T127 && ${res_oce} = TP10 ]] && slm_fraction=0.58
      [[ ${res_atm} = T159 && ${res_oce} = TP04 ]] && slm_fraction=0.59
      if [[ ${slm_fraction} = 0.5 ]]; then
        echo "------------------------------------------------------"
        echo "WARNING: no value for slm_fraction specified for ${res_atm} ${res_oce}."
        echo "         Are you sure you want to use the default (0.5)?"
        echo "------------------------------------------------------"
      fi
      cdo gec,${slm_fraction} -selvar,SLM ${CFILE} slm
    fi
    cdo chname,SLM,SLF ${CFILE} ${CFILE}.tmp
    ncatted -a 'long_name','SLF',o,c,'fractional land sea mask' ${CFILE}.tmp
    mv ${CFILE}.tmp ${CFILE}

    if [[ ${with_lakes} = true ]]; then
      # merge lake mask into the land sea masks

      cdo selvar,ALAKE ${AFILE} lake  # fract. lakes from uncoupled echam
      cdo selvar,SLF ${CFILE} slf     # fract. mask without lakes

      cdo -gec,1 slf slm1
      cdo mul lake slm1 new_lake      # there should not be lakes at the coasts
      cdo sub slf new_lake new_slf

      cdo -gec,0.5 new_lake lake1
      cdo sub slm lake1 new_slm       # integer mask with lakes
      ncatted -a 'units','SLM',o,c,'1' new_slm
      cdo merge new_slm ${CFILE} ${CFILE}.tmp
      cdo replace ${CFILE}.tmp new_slf ${CFILE}
      cdo replace ${CFILE} new_lake ${CFILE}.tmp
      mv ${CFILE}.tmp ${CFILE}
      rm slm slm1 new_slm slf new_slf lake lake1 new_lake
    else
      cdo selvar,SLF ${CFILE} slf     # fract. mask without lakes
      ncatted -a 'units','SLM',o,c,'1' slm
      cdo merge slm ${CFILE} ${CFILE}.tmp
      mv ${CFILE}.tmp ${CFILE}
      rm slm slf
    fi
  else
    cp -p ${pool_atm}/${res_atm}/${res_atm}${res_oce}_VGRATCLIM.nc  .
    cp -p ${pool_atm}/${res_atm}/${res_atm}${res_oce}_VLTCLIM.nc    .
    cp -p ${pool_atm}/${res_atm}/${res_atm}${res_oce}_jan_surf.nc   .
    cp -p ${pool_atm}/${res_atm}/amip2/${res_atm}_amip2sic_clim.nc  .
    cp -p ${pool_atm}/${res_atm}/amip2/${res_atm}_amip2sst_clim.nc  .
  fi

  for ivres_atm in ${vres_atm} ; do
    #cp -p ${pool_atm}/${res_atm}/${res_atm}${ivres_atm}_jan_spec.nc .
    cp -p ${pool_atm_standalone}/${res_atm}/${res_atm}${ivres_atm}_jan_spec.nc .
  done
  cp -p ${pool_atm}/${res_atm}/${res_atm}_O3clim2.nc                  .
  cp -p ${pool_atm}/${res_atm}/${res_atm}_ozone_CMIP5_1850-1860.nc    .
  cp -p ${pool_atm}/${res_atm}/${res_atm}_ozone_CMIP5_1979-1988.nc    .
  cp -p ${pool_atm}/${res_atm}/${res_atm}_TSLCLIM2.nc                 .
  cp -p ${pool_atm}/rrtmg_lw.nc              .
  cp -p ${pool_atm}/ECHAM6_CldOptProps.nc    .
  cp -p ${pool_atm}/surrta_data              .
  cp -p ${pool_atm}/hdpara.nc                .
  cp -p ${pool_atm}/hdstart.nc               .

  cd ${wrkdir}

  tarfile="${tarfile}_${res_atm}${vres_atm}"
fi

#-------------------------------------
# JSBACH input files
#-------------------------------------
if [[ "${srfinp}" = "yes" ]]; then

  if [[ ${cplmod} = s ]]; then
    mkdir -p input/echam6
    cd input/echam6
    cp -p ${pool_atm}/${res_atm}/${res_atm}${res_oce}_VGRATCLIM.nc  .
    cp -p ${pool_atm}/${res_atm}/${res_atm}${res_oce}_VLTCLIM.nc    .
    cp -p ${pool_atm}/${res_atm}/${res_atm}${res_oce}_jan_surf.nc   .
    cp -p ${pool_atm}/${res_atm}/${res_atm}_TSLCLIM2.nc             .
    cd ../..
  fi  
  mkdir -p input/jsbach
  cd input/jsbach

  # cmip5-like initial file
  export dynveg=true
  export year_ct=1850; export year_cf=1850
  export ntiles=11
  export c3c4crop=true
  export cmip5_pasture=true

  ${srcdir}/jsbach_init_file.ksh

  # cmip5-like initial file with own tile for glaciers
  export dynveg=true
  export year_ct=1850; export year_cf=1850
  export ntiles=12
  export c3c4crop=true
  export cmip5_pasture=true

  ${srcdir}/jsbach_init_file.ksh

  # millennium-like initial file (but with C3/C4 crops)
  export dynveg=false
  export year_ct=800; export year_cf=800
  export ntiles=4
  export c3c4crop=true
  export cmip5_pasture=false

  ${srcdir}/jsbach_init_file.ksh

  # initial file for dynamic vegetation (only natural)
  export dynveg=true
  export year_ct=800; export year_cf=800
  export ntiles=8
  export c3c4crop=false
  export cmip5_pasture=false

  ${srcdir}/jsbach_init_file.ksh
    
  # present day initial file (4 tiles)
  export dynveg=false
  export year_ct=1992; export year_cf=1992
  export ntiles=4
  export c3c4crop=true
  export cmip5_pasture=false

  ${srcdir}/jsbach_init_file.ksh

  # present day initial file (11 tiles)
  export dynveg=true
  export year_ct=1976; export year_cf=1976
  export ntiles=11
  export c3c4crop=true
  export cmip5_pasture=true

  ${srcdir}/jsbach_init_file.ksh

  # present day initial file (11 tiles)
  export dynveg=true
  export year_ct=1992; export year_cf=1992
  export ntiles=11
  export c3c4crop=true
  export cmip5_pasture=false

  ${srcdir}/jsbach_init_file.ksh

  # present day initial file (12 tiles, only glacier on first)
  export dynveg=true
  export year_ct=1992; export year_cf=1992
  export ntiles=12
  export c3c4crop=true
  export cmip5_pasture=false

  ${srcdir}/jsbach_init_file.ksh

  # remove the executable and modules
  rm jsbach_init_file mo_kinds.mod mo_vegparams.mod

  if [[ "${atminp}" = "no" ]]; then
    if [[ ${res_atm} != T31 ]]; then
      echo "no climate data file for jsbach available in ${res_atm}"
      exit 1
    fi
    cp -p ${pool_srf}/${res_atm}/Climate.T31.nc         Climate.T31.nc       

    tarfile="${tarfile}_${res_atm}"
  fi
  cd ${wrkdir}
fi

#-------------------------------------
# MPIOM input files
#-------------------------------------
if [[ "${oceinp}" = "yes" ]]; then

  mkdir -p input/mpiom
  chmod -R 755 input/mpiom
  cd input/mpiom
  for ivres_oce in ${vres_oce}; do
    cp -p ${pool_oce}/${res_oce}/${res_oce}${ivres_oce}_INISAL_PHC  ${res_oce}${ivres_oce}_INISAL_PHC
    cp -p ${pool_oce}/${res_oce}/${res_oce}${ivres_oce}_INITEM_PHC  ${res_oce}${ivres_oce}_INITEM_PHC
    cp -p ${pool_oce}/${res_oce}/${res_oce}${ivres_oce}_SURSAL_PHC  ${res_oce}${ivres_oce}_SURSAL_PHC
  done
  cp -p ${pool_oce}/${res_oce}/${res_oce}_BEK                    ${res_oce}_BEK
  cp -p ${pool_oce}/${res_oce}/${res_oce}_anta                   ${res_oce}_anta
  cp -p ${pool_oce}/${res_oce}/${res_oce}_arcgri                 ${res_oce}_arcgri
  cp -p ${pool_oce}/${res_oce}/${res_oce}_topo                   ${res_oce}_topo
  cp -p ${pool_oce}/${res_oce}/${res_oce}s.nc                    ${res_oce}s.nc
  cp -p ${pool_oce}/${res_oce}/${res_oce}u.nc                    ${res_oce}u.nc
  cp -p ${pool_oce}/${res_oce}/${res_oce}v.nc                    ${res_oce}v.nc

  if [[ "${lcouple}" != ".true." ]]; then
    cp -p ${pool_oce}/${res_oce}/${res_oce}_GI*_OMIP365 .
    cp -p ${pool_oce}/runoff_pos .
    cp -p ${pool_oce}/runoff_obs .
  fi

  cd ${wrkdir}
  chmod 644 input/mpiom/*
  if [[ ${restart_mpiom} != "" ]]; then
    mkdir -p restart/mpiom
    cp -p ${restart_mpiom} restart/mpiom/rerun_mpiom.ext
    chmod 644 restart/mpiom/*
  fi

  tarfile="${tarfile}_${res_oce}${vres_oce}"
fi

#-------------------------------------
# HAMOCC input files
#-------------------------------------
if [[ "$(echo ${cplmod} | grep b)" = "${cplmod}" ]]; then    # hamocc

  mkdir -p input/hamocc
  chmod -R 755 input/hamocc
  cd input/hamocc
  cp -p ${pool_oce}/${res_oce}/${res_oce}_INPDUST.nc  ${res_oce}_INPDUST.nc
  cp -p ${pool_oce}/${res_oce}/${res_oce}_LUODUST.nc  ${res_oce}_LUODUST.nc
  cp -p ${pool_oce}/${res_oce}/${res_oce}_MAHOWALDDUST.nc  ${res_oce}_MAHOWALDDUST.nc

  cat >hamocc_sed_level_file <<EOF
zaxistype : depth_below_sea
size      : 12
levels    : 1 4 9 16 25 36 49 64 81 100 121 144
EOF

  cd ${wrkdir}
  chmod 644 input/hamocc/*
  if [[ ${restart_hamocc} != "" ]]; then
    mkdir -p restart/hamocc
    cp -p ${restart_hamocc} restart/hamocc/rerun_hamocc.nc
    chmod 644 restart/hamocc/*
  fi
fi

[[ ${cplmod} = s ]] && rm -rf input/echam6
if [[ -d restart ]]; then
  tar cvf ${tarfile}.tar input restart
else
  tar cvf ${tarfile}.tar input
fi
mkdir -p ${pool_cpl}/cosmos-${cplmod}
mv ${tarfile}.tar ${pool_cpl}/cosmos-${cplmod}

echo "\nInput tarfile ${tarfile}.tar created and moved to ${pool_cpl}/cosmos-${cplmod}\n"

exit 0
