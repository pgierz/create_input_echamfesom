#!/bin/ksh
#------------------------------------------------------------------------------
# Script to compile and run jsbach_init_file.f90
# For more information read the header of jsbach_init_file.f90.
#
# The script is usually called by create_input_cosmos.ksh, were several
# variables are exported (interactive=false).
# Alternatively, it can be run interactively (interactive=true), to just create
# a specific initial file for jsbach.
#
# To generate a series of vegetation cover maps for runs with landcover change,
# the script needs to be called interactivly with landcover_series=true
#
# Veronika Gayler
# Stiig Wilkenskjeld, 2012-01: Added variables for 5 layer soil scheme
#------------------------------------------------------------------------------
set -e

if [[ $interactive_ctrl -eq 1 ]]; then
	interactive=false
else
	interactive=true
fi

# Variables that need to be defined if the sript is used interctively.
# If called from create_input_cosmos.ksh these variables are exported.
#
if [[ ${interactive} = true ]]; then
  res_atm=T63                 # horizontal grid resopution
  res_oce=GR15                # ocean model grid (for a coupled setup)

  ntiles=11                   # number of jsbach tiles

  dynveg=false                # setup for dynamic vegetation:
                              #   - cover fractions of natural vegetation included
                              #   - soil water capacity increased in desert areas 
  c3c4crop=true               # differentiate between C3 and C4 crops
  lpasture=true               # distinguish pastures from grasses
  read_pasture=LUH2v2h        # LUH: read pastures and crops from LUH states as in CMIP5
                              # LUH2v2h: read pastures and crops from LUH2 states as in CMIP6
                              # false: no separate input file for crops and pastures
  pasture_rule=true           # allocate pastures primarily on grass lands

  year_ct=1850                # year the cover_types are derived from (0000 for natural vegetation)
  year_cf=1850                # year cover fractions are derived from (0000 for natural vegetation)

  landcover_series=false      # generate a series of files with cover_types of
                              # year_ct and fractions from year_cf to year_cf2
  year_cf2=1859               # only used with landcover_series

  echam_fractional=false      # initial file for echam runs with fractional
                              # land sea mask
  masks_file=default          # file with land sea mask (default: use echam land sea mask)

#  pool=/pool/data/ECHAM5/${res_atm} # directories with echam input data
#  pool=/pool/data/JSBACH/prepare/${res_atm}/ECHAM6/ # directories with echam input data
  pool=/pool/data/ECHAM6/input/r0006/${res_atm}   # directories with echam input data
  pool_land=/pool/data/JSBACH/prepare/${res_atm}
  srcdir=.
else
  #TR USE WHICH SETTINGS FOR ELSE CASE? CHECK WITH TIDO
  pool=${wrkdir}/input/echam6
  pool_land=/pool/data/JSBACH/prepare/${res_atm}/

  #landcover_series=false  
  #year_cf2=1859 # only used with landcover_series

  #echam_fractional=false

  #lpasture=true 
  #read_pasture=LUH2v2h #LUH2v2h
  #pasture_rule=true 

  #dynveg=false 
  #masks_file=default
fi

#------------------------------------------------------------------------------

if [[ `hostname` == mlogin* || `hostname` == mistralpp* ]]; then

# Options for DKRZ linux cluster mistral
  F90=nagfor
  F90FLAGS="-colour -maxcontin=100 -wmismatch=define_var_new,nf_get_var_double,nf_copy_att,nf_get_var_real,nf_put_var_double,nf_def_var,nf_put_vara_double,dgemm,nfmpi_def_dim,nfmpi_put_vara_double,nfmpi_def_var -C=all -g -gline -nan -w=uep"

  NETCDFFROOT=/sw/rhel6-x64/netcdf/netcdf_fortran-4.4.2-static-nag60
  NETCDFROOT=/sw/rhel6-x64/netcdf/netcdf_c-4.4.0-gcc48
  HDF5ROOT=/sw/rhel6-x64/hdf5/hdf5-1.8.14-threadsafe-gcc48
  SZIPROOT=/sw/rhel6-x64/sys/libaec-0.3.2-gcc48
  ZLIBROOT=/usr/lib64

  NETCDFF_LIBDIR="-L${NETCDFFROOT}/lib"
  NETCDFF_LIB="-lnetcdff"
  NETCDFF_INCLUDE="-I${NETCDFFROOT}/include"
  
  NETCDF_LIBDIR="-L${NETCDFROOT}/lib"
  NETCDF_LIB="-lnetcdf"
  NETCDF_INCLUDE="-I${NETCDFROOT}/include"

  HDF5_LIBDIR="-L${HDF5ROOT}/lib"
  HDF5_LIB="-lhdf5_hl -lhdf5 -ldl"

  SZIP_LIBDIR="-L${SZIPROOT}/lib"
  SZIP_LIB="-lsz"

  ZLIB_LIBDIR="-L${ZLIBROOT}/lib"
  ZLIB_LIB="-lz -ldl -lm -lnuma -Wl,--export-dynamic -lrt -lnsl -lutil -lm -ldl"
  export LD_LIBRARY_PATH="/sw/rhel6-x64/hdf5/hdf5-1.8.14-threadsafe-gcc48/lib:/sw/rhel6-x64/netcdf/netcdf_c-4.4.0-gcc48/lib:/sw/rhel6-x64/sys/libaec-0.3.2-gcc48/lib"

else
# Options for NAG compiler on linux-x64
 
  F90=nagfor
  F90FLAGS="-colour -maxcontin=100 -wmismatch=define_var_new,nf_get_var_double,nf_copy_att,nf_get_var_real,nf_put_var_double,nf_def_var,nf_put_vara_double,dgemm,nfmpi_def_dim,nfmpi_put_vara_double,nfmpi_def_var -C=all -g -gline -nan -w=uep"
   
  NETCDFFROOT="/sw/jessie-x64/netcdf_fortran-4.4.2-static-nag60/"
  NETCDFROOT="/sw/jessie-x64/netcdf-4.3.3.1-static-gccsys/"
  HDF5ROOT="/sw/jessie-x64/hdf5-1.8.16-static-gccsys/"
  SZIPROOT="/sw/jessie-x64/szip-2.1-static-gccsys/"

  NETCDFF_INCLUDE="-I${NETCDFFROOT}/include"
  NETCDFF_LIBDIR="-L${NETCDFFROOT}/lib"
  NETCDFF_LIB="-lnetcdff"
  NETCDF_LIBDIR="-L${NETCDFROOT}/lib"
  NETCDF_LIB="-lnetcdf"

  HDF5_LIBDIR="-L${HDF5ROOT}/lib"
  HDF5_LIB="-lhdf5_hl -lhdf5 -ldl"

  SZIP_LIBDIR="-L${SZIPROOT}/lib"
  SZIP_LIB="-lsz -lz"

fi

#------------------------------------------------------------------------------
# Compilation
#------------------------------------------------------------------------------
prog=jsbach_init_file

if [[ ${interactive} = true ]] && [[ -f ${prog} ]]; then
  newer=$(ls -t ${prog} ${prog}.f90 | head -1)
  [[ ${newer} = ${prog} ]] || rm ${prog}
fi

if [[ ! -f ${prog} ]]; then
  echo "Compile ${srcdir}/${prog}.f90..."
  ${F90} ${F90FLAGS} -o ${prog} ${srcdir}/${prog}.f90 ${NETCDFF_INCLUDE}  ${NETCDFF_LIBDIR} ${NETCDFF_LIB} ${NETCDF_LIBDIR} ${NETCDF_LIB} ${HDF5_LIBDIR} ${HDF5_LIB} ${SZIP_LIBDIR} ${SZIP_LIB} ${ZLIB_LIBDIR} ${ZLIB_LIB}
fi
if [[ -f ${prog} ]]; then

#------------------------------------------------------------------------------
# prepare the namelist
#------------------------------------------------------------------------------

  [[ ${res_oce} = "" ]] && lcouple=.false. || lcouple=.true.
  [[ ${dynveg} = true ]] && ldynveg=.true. || ldynveg=.false.
  [[ ${c3c4crop} = true ]] && lc3c4crop=.true. || lc3c4crop=.false.
  [[ ${read_pasture} != false ]] && lread_pasture=.true. || lread_pasture=.false.
  [[ ${landcover_series} = false ]] && year_cf2=${year_cf}

  desert_only=.false.         # setup for a desert-only experiment
  grass_only=.false.          # setup for a grass-only experiment
  woods_only=.false.          # setup for a woods-only experiment

  cat > namelist <<EOF
&INITCTL
  res_atm="${res_atm}"
  res_oce="${res_oce}"
  ntiles=${ntiles}
  nlct=21
  year_ct=${year_ct}
  year_cf=${year_cf}
  lcouple=${lcouple}
  ldynveg=${ldynveg}
  lc3c4crop=${lc3c4crop}
  lpasture=${lpasture}
  lread_pasture=${lread_pasture}
  pasture_tag="${read_pasture}"
  lpasture_rule=.${pasture_rule}.
  echam_fractional=.${echam_fractional}.
  masks_file="${masks_file##*/}"
  desert_only=${desert_only}
  grass_only=${grass_only}
  woods_only=${woods_only}
  cover_fract_only=.${landcover_series}.
  info=.false.
/
EOF

#------------------------------------------------------------------------------
# get input data from the pools
#------------------------------------------------------------------------------

  ln -sf ${pool}/${res_atm}${res_oce}_jan_surf.nc  .
  ln -sf ${pool}/${res_atm}${res_oce}_VGRATCLIM.nc .
  ln -sf ${pool}/${res_atm}${res_oce}_VLTCLIM.nc   .
  if [[ -f ${pool}/${res_atm}_TSLCLIM2.nc ]]; then
    ln -sf ${pool}/${res_atm}_TSLCLIM2.nc  .
  else
    ln -sf ${pool}/${res_atm}_TSLCLIM.nc   ${res_atm}_TSLCLIM2.nc
  fi
  if [ $(echo ${res_atm} | cut -c1) != T ]; then
    res_atmg=${res_atm}
  else
    res_atmg=${res_atm}gauss
  fi
  if [[ ${read_pasture} = false ]]; then
    ln -sf ${pool_land}/vegtype_${year_cf}_${res_atmg}_pa14.nc\
                        vegtype_${year_cf}_${res_atm}gauss_pa14.nc
    if [[ ${year_cf} != ${year_ct} ]]; then
      ln -sf ${pool_land}/vegtype_${year_ct}_${res_atmg}_pa14.nc \
                        vegtype_${year_ct}_${res_atm}gauss_pa14.nc
    fi
  fi
  ln -sf ${pool_land}/vegmax_6_${res_atm}_0-360.nc  \
                      vegmax_6_${res_atm}.nc
  ln -sf ${pool_land}/${res_atm}_topo_75.nc     .
  ln -sf ${pool_land}/albedo_${res_atm}.nc      .
  ln -sf ${pool_land}/C3C4_mask_${res_atmg}.nc \
                      C3C4_mask_${res_atm}gauss.nc
  ln -sf ${pool_land}/potveg_${res_atm}.nc      .
  if [[ ${c3c4crop} = true ]]; then
    if [[ ${read_pasture} = LUH2v2h ]]; then
      ln -sf ${pool_land}/C3C4_crop_LUH2v2h_${res_atm}.nc \
                          C3C4_crop_${res_atm}.nc
    else
      ln -sf ${pool_land}/C3C4_crop_${res_atm}.nc \
                          C3C4_crop_${res_atm}.nc
    fi
  fi
  if [[ ${read_pasture} = LUH2v2h ]]; then
    if [[ ${dynveg} = true ]]; then
      LUH_states=LUH2v2h_states_${res_atm}_dynveg.nc
    else
      LUH_states=LUH2v2h_states_${res_atm}_all-oceans_no-dynveg.nc
    fi
  elif [[ ${read_pasture} = LUH ]]; then
    LUH_states=LUH_states_${res_atm}.nc
  fi
  if [[ ${read_pasture} != false ]]; then
    if [[ -f ${pool_land}/${LUH_states} ]]; then
      ln -sf ${pool_land}/${LUH_states} .
    elif  [[ -f ${pool_land}/${LUH_states}.gz ]]; then
      cp ${pool_land}/${LUH_states}.gz .
      gunzip ${LUH_states}.gz
    fi
    typeset -Z 4 yr=${year_cf}
    while [[ ${yr} -le ${year_cf2} ]]; do
      cdo selyear,${yr} ${LUH_states} LUH_states_${yr}_${res_atm}.nc
      (( yr = yr + 1 ))
    done
  fi
  [[ ${masks_file} != default && ! -f ${masks_file##*/} ]] && ln -sf ${masks_file} .
      
  ln -sf ${pool_land}/soil_parameters_${res_atm}.nc .

#------------------------------------------------------------------------------
# run the program
#------------------------------------------------------------------------------

  echo "Run ${prog}..."
  chmod 755 ${prog}

  yr=${year_cf}
  while [[ ${yr} -le ${year_cf2} ]]; do

    sed "s/year_cf=.*/year_cf=${yr}/" namelist > namelist.tmp
    mv namelist.tmp namelist
    ./${prog}

    (( yr = yr + 1 ))
  done

#------------------------------------------------------------------------------
# clean up
#------------------------------------------------------------------------------

  if [[ $? -eq 0 ]]; then
    rm namelist
    rm ${res_atm}${res_oce}_jan_surf.nc
    rm ${res_atm}${res_oce}_VGRATCLIM.nc 
    rm ${res_atm}${res_oce}_VLTCLIM.nc
    rm ${res_atm}_TSLCLIM2.nc
    if [[ ${read_pasture} = false ]]; then
      rm vegtype_${year_cf}_${res_atm}gauss_pa14.nc
      if [[ ${year_cf} != ${year_ct} ]]; then
        rm vegtype_${year_ct}_${res_atm}gauss_pa14.nc
      fi
    fi
    rm vegmax_6_${res_atm}.nc
    rm ${res_atm}_topo_75.nc
    rm albedo_${res_atm}.nc
    rm C3C4_mask_${res_atm}gauss.nc
    rm potveg_${res_atm}.nc
    if [[ ${c3c4crop} = true ]]; then
      rm C3C4_crop_${res_atm}.nc
    fi
    if [[ ${read_pasture} != false ]]; then
      rm ${LUH_states}
      rm LUH_states_????_${res_atm}.nc
    fi
    if [[ ${interactive} = true ]]; then
      [[ -f mo_kinds.mod ]] && rm mo_kinds.mod
      [[ -f mo_vegparams.mod ]] && rm mo_vegparams.mod
    fi
    rm -f 5soillayers_${res_atm}.nc soil_parameters_${res_atm}.nc
    [[ -L ${masks_file} ]] &&  rm ${masks_file}
  else
    echo "error in ${prog}"
    exit 1  
  fi
else
  echo "${prog} could not be created"
  exit 1
fi
exit 0
