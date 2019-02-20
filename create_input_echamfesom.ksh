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
#   Thomas Rackow, AWI, November 2012
#	   -adapted for ECHAM-FESOM with unstructured ocean
#   Thomas Rackow, AWI, March 2015
#	   -direct mapping of (unstructured) ocean distribution to ECHAM's grid 
#   Thomas Rackow, AWI, September 2015
#          -remapping performed completely in this routine
#   Thomas Rackow, AWI, March 2016
#	   -force lsm values to be in [0,1] after remapycon
#   Thomas Rackow, AWI, November 2018
#          -put everything on gitlab@DKRZ
################################################################################
set -e
#module load cdo
#module load nco
#module load nag
################################################################################
# switch off interactive mode in the script jsbach_init_file.ksh
export interactive_ctrl=1

# coupled model acronym (as, aso, asob, o, ob etc.)
export cplmod=asob

# component model resolutions
export res_atm=T127 	# T31,T63,T127(L95),T255(L95)	# atmosphere horizontal resolution
export vres_atm=L95	# L47,L95        		# atmosphere vertical resolution
export res_oce=CORE2 	# ocean horizontal resolution (GLOB, CORE2, AGUV, DMIP, BOLD, FRON, PI)
export vres_oce=L46    # ocean vertical resolution

# set paths to FESOM meshes and CDO grid description files
if [[ "${res_oce}" = "CORE2" ]]; then
  export mesh_path=/work/bm0944/input/CORE2_final/
  export mesh_griddes=${mesh_path}/CORE2_final.txt.nc
elif [[ "${res_oce}" = "AGUV" ]]; then
  export mesh_path=/work/bm0944/input/aguv/
  export mesh_griddes=${mesh_path}/mesh_aguv_derot.nc
elif [[ "${res_oce}" = "GLOB" ]]; then
  export mesh_path=/work/ab0995/a270046/fesom-meshes/glob/
  export mesh_griddes=${mesh_path}/glob.rot.nc 		
elif [[ "${res_oce}" = "REF87K" ]]; then
  export mesh_path=/work/bm0944/input/mesh_ref87k/
  export mesh_griddes=${mesh_path}/ref87k_CDOgriddes.nc	
elif [[ "${res_oce}" = "PIGRID" ]]; then
  export mesh_path=/work/ab0995/a270046/meshes_default/pi-grid/
  export mesh_griddes=${mesh_path}/griddes.nc	
elif [[ "${res_oce}" = "LGM2" ]]; then
  export mesh_path=/work/ab0995/a270046/fesom-meshes/mesh_lgm2/
  export mesh_griddes=${mesh_path}/mesh_lgm2.txt.nc
elif [[ "${res_oce}" = "DMIP" ]]; then
  export mesh_path=/work/ab0995/a270046/fesom-meshes/dmip/
  export mesh_griddes=${mesh_path}/fesom_mesh_dmip.txt.nc
elif [[ "${res_oce}" = "BOLD" ]]; then
  export mesh_path=/work/ab0995/a270046/fesom-meshes/bold/
  export mesh_griddes=${mesh_path}/fesom_mesh_bold.txt.nc
elif [[ "${res_oce}" = "FRON" ]]; then
  #export mesh_path=/work/ab0995/a270067/fesom/fron/mesh_Agulhas/
  export mesh_path=/mnt/lustre01/work/bm0944/input/fron/
  export mesh_griddes=${mesh_path}/fesom_mesh_fron.txt.nc
fi

# input data
export pool_atm_standalone=/pool/data/ECHAM5                # pool with atm input data
[[ ${res_atm} = T127 ]] && export pool_atm_standalone=/work/mh0081/prep/echam6
[[ ${res_atm} = T255 ]] && export pool_atm_standalone=/work/im0454/ECHAM6 # does not exist anymore
export pool_atm=/pool/data/ECHAM6
export pool_oce=/pool/data/MPIOM                 # pool with oce input data
export pool_srf=/pool/data/JSBACH                # pool with srf input data
[[ ${res_atm} = T255 ]] && export pool_srf=/work/im0454/JSBACH   # pool with srf input data
#export pool_cpl=$WRKSHR/tarfiles           # pool for created input data
export pool_cpl=${mesh_path}/tarfiles${res_atm}_pool		# pool for created input data

# restart data
#restart_mpiom=""
#restart_hamocc=""

#export wrkdir=$WRKSHR/tarfiles/work.$$	# working directory for the tarfile generation  
export wrkdir=$pool_cpl			# working directory for the tarfile generation  

alias cdo=$(which cdo)

with_lakes=true      # generate echam and jsbach initial files with/without lakes

################################################################################

################################################################################
echo "------------------------------------------------------"
echo " Create ECHAM6.3 input files for ECHAM-FESOM depending"
echo " on FESOM ocean distribution on an unstructured mesh  "
echo "------------------------------------------------------"
echo " ATM RESOLUTION AND OCEAN MESH:" ${res_atm}${vres_atm}"," ${res_oce}${vres_oce}
echo " New input files in " ${pool_cpl} 
echo "------------------------------------------------------"
echo " By running this script you'll overwrite the ECHAM6 input files in the directory given above. Go on? (y/n) "
read txt

if [ "$txt" != "y" ]; then
exit 0
fi
echo "------------------------------------------------------"
################################################################################

tarfile=input_echamfesom-${cplmod}

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
    
    # we use the unstructured ocean mesh directly (remap FESOM ocean distribution to T63/T127/T255/... grids)
    export CDO_REMAP_NORMALIZE_OPT='dest' # options: (fracarea, destarea, none)
    cdo -f nc -remapycon,t${res_atm#T}grid -const,1,${mesh_griddes} echam_lsm_${CDO_REMAP_NORMALIZE_OPT}.nc
         
    # set missing values on land to zero; then switch definition to 1 for land and 0 for ocean	 
    cdo -f nc -mulc,-1 -addc,-1 -setmisstoc,0 echam_lsm_${CDO_REMAP_NORMALIZE_OPT}.nc ../../echam_lsm_before.nc
      
    # set small negative values to zero; values above 1 to 1
    cdo setmisstoc,1 -setrtomiss,1,1e33 -setmisstoc,0 -setrtomiss,-1e33,0 ../../echam_lsm_before.nc ../../echam_lsm.nc
 
    # original code: cdo setmisstoc,1 -remapcon,t${res_atm#T}grid ${pool_oce}/${res_oce}/${res_oce}_lsm.nc ../../echam_lsm.nc


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

      # FESOM ocean grids; target is the land fraction implied by the ocean grid
      [[ ${res_atm} = T127 && ${res_oce} = CORE2 ]] && slm_fraction=0.49 	# 0.48: SLM land frac 1.45555e+14;
										# 0.49: SLM land frac 1.45317e+14;
										# 0.50: SLM land frac 1.45088e+14; CORE2 land frac 1.4531e+14

      [[ ${res_atm} = T63 && ${res_oce} = CORE2 ]] && slm_fraction=0.46 	# 0.46:	SLM land/oce frac 1.45449e+14/3.64616e+14 
										# 0.47:	SLM land/oce frac 1.45145e+14/3.64919e+14
										# 0.48: SLM land/oce frac 1.44630e+14/3.65435e+14
										# 0.49: SLM land/oce frac 1.44363e+14/3.65702e+14
										# 0.50: SLM land/oce frac 1.43986e+14/3.66079e+14; CORE2 land frac 1.4531e+14

      [[ ${res_atm} = T63 && ${res_oce} = GLOB ]] && slm_fraction=0.47 		# 0.47: SLM land/oce frac 1.48175e+14/3.61889e+14
										# 0.48: SLM land/oce frac 1.47768e+14/3.62296e+14
										# 0.49: SLM land/oce frac 1.47298e+14/3.62766e+14
										# 0.50: SLM land/oce frac 1.46903e+14/3.63161e+14; GLOB land frac 1.48128e+14											
      [[ ${res_atm} = T127 && ${res_oce} = GLOB ]] && slm_fraction=0.49 	# 0.48: SLM land/oce frac 1.48402e+1/3.61662e+14
										# 0.49: SLM land/oce frac 1.48123e+14/3.61941e+14
										# 0.50: SLM land/oce frac 1.47799e+14/3.62265e+14; GLOB land frac 1.48128e+14

      [[ ${res_atm} = T127 && ${res_oce} = AGUV ]] && slm_fraction=0.49 	# 0.48: SLM land/oce frac 1.49326e+14/3.60739e+14
										# 0.49: SLM land/oce frac 1.49130e+14/3.60935e+14
										# 0.50: SLM land/oce frac 1.48883e+14/3.61182e+14; AGUV land frac 1.4923e+14

      [[ ${res_atm} = T63 && ${res_oce} = AGUV ]] && slm_fraction=0.47		# 0.47: SLM land/oce frac 1.49458e+14/3.60606e+14	
										# 0.48: SLM land/oce frac 1.48913e+14/3.61152e+14	
										# 0.49: SLM land/oce frac 1.48522e+14/3.61542e+14
										# 0.50: SLM land/oce frac 1.48101e+14/3.61963e+14; AGUV land frac 1.4923e+14

      [[ ${res_atm} = T63 && ${res_oce} = REF87K ]] && slm_fraction=0.49	# 0.49: SLM land/oce frac 1.53286e+14/3.56779e+14
										# 0.50: SLM land/oce frac 1.52955e+14/3.57109e+14; REF87K land frac 1.53205e+14

      [[ ${res_atm} = T127 && ${res_oce} = REF87K ]] && slm_fraction=0.50	# 0.51: SLM land/oce frac 1.53024e+14/3.5704e+14
										# 0.50: SLM land/oce frac 1.53256e+14/3.56808e+14; REF87K land frac 1.53205e+14	

      [[ ${res_atm} = T63 && ${res_oce} = LGM2 ]] && slm_fraction=0.48		# 0.48: SLM land/oce frac 1.73900e+14/3.36164e+14	
										# 0.49: SLM land/oce frac 1.73607e+14/3.36458e+14
										# 0.50: SLM land/oce frac 1.73371e+14/3.36694e+14; LGM2 land frac 1.73909e+14	

      [[ ${res_atm} = T127 && ${res_oce} = DMIP ]] && slm_fraction=0.48		# 0.48: SLM land/oce frac 1.48481e+14/3.61583e+14	
										# 0.49: SLM land/oce frac 1.48239e+14/3.61825e+14
										# 0.50: SLM land/oce frac 1.48024e+14/3.62041e+14; DMIP land frac 1.48373e+14

      [[ ${res_atm} = T127 && ${res_oce} = BOLD ]] && slm_fraction=0.48		# 0.48: SLM land/oce frac 1.48301e+14/3.61764e+14
										# 0.49: SLM land/oce frac 1.48030e+14/3.62034e+14
										# 0.50: SLM land/oce frac 1.47826e+14/3.62238e+14; BOLD land frac 1.48255e+14

      [[ ${res_atm} = T255 && ${res_oce} = BOLD ]] && slm_fraction=0.49		# 0.48: SLM land/oce frac 1.48384e+14/3.61681e+14
										# 0.49: SLM land/oce frac 1.48227e+14/3.61837e+14; BOLD land frac 1.48255e+14

      [[ ${res_atm} = T63 && ${res_oce} = BOLD ]] && slm_fraction=0.47		# 0.46: SLM land/oce frac 1.48624e+14/3.61441e+14
										# 0.47: SLM land/oce frac 1.48194e+14/3.61870e+14
										# 0.48: SLM land/oce frac 1.47841e+14/3.62223e+14
										# 0.49: SLM land/oce frac 1.47468e+14/3.62596e+14 
										# 0.50: SLM land/oce frac 1.46844e+14/3.63221e+14; BOLD land frac 1.48255e+14

      [[ ${res_atm} = T127 && ${res_oce} = FRON ]] && slm_fraction=0.49		# 0.48: SLM land/oce frac 1.47089e+14/3.62975e+14;
										# 0.49: SLM land/oce frac 1.46781e+14/3.63283e+14; FRON land frac 1.46909e+14

      [[ ${res_atm} = T255 && ${res_oce} = FRON ]] && slm_fraction=0.49		# 0.48: SLM land/oce frac 1.47032e+14/3.63032e+14
										# 0.49: SLM land/oce frac 1.46890e+14/3.63175e+14; FRON land frac 1.46909e+14

      [[ ${res_atm} = T63 && ${res_oce} = PIGRID ]] && slm_fraction=0.50	# 0.50: SLM land/oce frac 1.69612e+14/3.40453e+14; PIGRID land frac 1.70003e+14

      [[ ${res_atm} = T127 && ${res_oce} = PIGRID ]] && slm_fraction=0.50	# 0.50: SLM land/oce frac 1.69949e+14/3.40116e+14; PIGRID land frac 1.70003e+14

      [[ ${res_atm} = T31 && ${res_oce} = PIGRID ]] && slm_fraction=0.50	# 0.50: SLM land/oce frac 1.69685e+14/3.40379e+14; PIGRID land frac 1.70003e+14


      if [[ ${slm_fraction} = 0.5 ]]; then
        echo "------------------------------------------------------"
        echo "WARNING: no value for slm_fraction specified for ${res_atm} ${res_oce}."
        echo "         Are you sure you want to use the default (0.5)?"
        echo "------------------------------------------------------"
      fi
      #compute integer land sea mask from "SLF", where SLF >= 0.5 (or slm_frac)
      cdo gec,${slm_fraction} -selvar,SLM ${CFILE} slm

      # diagnose land fraction 
      echo "------------------------------------------------------"
      echo "SLM land fraction, MPI target 147 Mio km2:" 
      cdo -s output -fldsum -mul slm -gridarea slm
      echo "${res_oce} mesh land fraction, AWI target:" 
      cdo -s output -sub -fldsum -gridarea -const,1,t63grid -fldsum -gridarea -const,1,${mesh_griddes} # total FESOM land
      echo "SLM ocean fraction:" 
      cdo -s output -fldsum -mul -mulc,-1 -subc,1 slm -gridarea slm
      echo "------------------------------------------------------"

    fi
    # change name of slm to slf in *_jan_surf.nc file
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

  # ----------------------------------------
  # TR added this general block
  export masks_file=default # uses the generated echam land sea mask
  export echam_fractional=false
  export landcover_series=false # will be true below for certain cases
  # ----------------------------------------

  # ----------------------------------------
  # cmip5-like initial file
  export dynveg=false 		#true	# Input file LUH2v2h_states_T127_dynveg.nc of process selyear does not exists
  export year_ct=1850; export year_cf=1850
  export ntiles=11
  export c3c4crop=true

  # export cmip5_pasture=true
  # seems to be replaced by:
  export lpasture=true 		# distinguish pastures from grasses
  export read_pasture=LUH2v2h 	# LUH: read pastures and crops from LUH states as in CMIP5
				# LUH2v2h: read pastures and crops from LUH2 states as in CMIP6
				# false: no separate input file for crops and pastures
  export pasture_rule=true 	# allocate pastures primarily on grass lands          

  ${srcdir}/jsbach_init_file.ksh

  # ...same with no-dynveg
  #export dynveg=false
  #
  #${srcdir}/jsbach_init_file.ksh

  # ----------------------------------------

  ## cmip5-like initial file with own tile for glaciers
  #export dynveg=true
  #export year_ct=1850; export year_cf=1850
  #export ntiles=12
  #export c3c4crop=true
  #export cmip5_pasture=true
  #
  #${srcdir}/jsbach_init_file.ksh

  ## millennium-like initial file (but with C3/C4 crops)
  #export dynveg=false
  #export year_ct=800; export year_cf=800
  #export ntiles=4
  #export c3c4crop=true
  #export cmip5_pasture=false
  #
  #${srcdir}/jsbach_init_file.ksh

  ## initial file for dynamic vegetation (only natural)
  #export dynveg=true
  #export year_ct=800; export year_cf=800
  #export ntiles=8
  #export c3c4crop=false
  #export cmip5_pasture=false
  #
  #${srcdir}/jsbach_init_file.ksh
    
  ## present day initial file (4 tiles)
  #export dynveg=false
  #export year_ct=1992; export year_cf=1992
  #export ntiles=4
  #export c3c4crop=true
  #export cmip5_pasture=false
  #
  #${srcdir}/jsbach_init_file.ksh

  # ----------------------------------------
  # present day initial file (11 tiles)
  export dynveg=false #true
  export year_ct=1976; export year_cf=1976
  export ntiles=11
  export c3c4crop=true
  export cmip5_pasture=true

  ${srcdir}/jsbach_init_file.ksh

  # ...same with no-dynveg
  #export dynveg=false
  #
  #${srcdir}/jsbach_init_file.ksh
  # ----------------------------------------

  # ----------------------------------------
  # present day initial file (11 tiles)
  export dynveg=false #true
  export year_ct=1992; export year_cf=1992
  export ntiles=11
  export c3c4crop=true
  export cmip5_pasture=false

  ${srcdir}/jsbach_init_file.ksh

  ## ...same with no-dynveg
  #export dynveg=false
  #
  #${srcdir}/jsbach_init_file.ksh
  # ----------------------------------------

  ## present day initial file (12 tiles, only glacier on first)
  #export dynveg=true
  #export year_ct=1992; export year_cf=1992
  #export ntiles=12
  #export c3c4crop=true
  #export cmip5_pasture=false
  #
  #${srcdir}/jsbach_init_file.ksh

  # ----------------------------------------
  # ADD A CASE FOR SCENARIO, COVERTYPE AND FRACT
  # ----------------------------------------

  ## TR, this case works but we decided to use the MPI files since the dependence to the ocean grid was dropped
  #export landcover_series=true	# generate a series of files with cover_types of
  #                            	# year_ct and fractions from year_cf to year_cf2
  #export year_cf2=2014		# only used with landcover_series
  #
  #export ntiles=11		# number of jsbach tiles
  #export dynveg=false           # setup for dynamic vegetation:
  #                            	#   - cover fractions of natural vegetation included
  #                            	#   - soil water capacity increased in desert areas 
  #export year_ct=1850
  #export year_cf=1850
  #export pasture_rule=true
  #
  #${srcdir}/jsbach_init_file.ksh

#if [[ ${interactive} = true ]]; then
#
#
#  c3c4crop=true               # differentiate between C3 and C4 crops
#  lpasture=true               # distinguish pastures from grasses
#  read_pasture=LUH2v2h        # LUH: read pastures and crops from LUH states as in CMIP5
                              # LUH2v2h: read pastures and crops from LUH2 states as in CMIP6
                              # false: no separate input file for crops and pastures
#  pasture_rule=true           # allocate pastures primarily on grass lands
#
#  year_ct=1850                # year the cover_types are derived from (0000 for natural vegetation)
#  year_cf=1850                # year cover fractions are derived from (0000 for natural vegetation)



#  echam_fractional=false      # initial file for echam runs with fractional
                              # land sea mask
#  masks_file=default          # file with land sea mask (default: use echam land sea mask)

#  pool=/pool/data/ECHAM5/${res_atm} # directories with echam input data
#  pool=/pool/data/JSBACH/prepare/${res_atm}/ECHAM6/ # directories with echam input data
#  pool=/pool/data/ECHAM6/input/r0006/${res_atm}   # directories with echam input data
#  pool_land=/pool/data/JSBACH/prepare/${res_atm}
#  srcdir=.
#else
#  #TR USE WHICH SETTINGS FOR ELSE CASE? CHECK WITH TIDO
#  pool=${wrkdir}/input/echam6
#  pool_land=/pool/data/JSBACH/prepare/${res_atm}/

  #landcover_series=false  
  #year_cf2=1859 # only used with landcover_series

  #echam_fractional=false

  #lpasture=true 
  #read_pasture=LUH2v2h #LUH2v2h
  #pasture_rule=true 

  #dynveg=false 
  #masks_file=default
#fi



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

##-------------------------------------
## MPIOM input files
##-------------------------------------
#if [[ "${oceinp}" = "yes" ]]; then
#
#  mkdir -p input/mpiom
#  chmod -R 755 input/mpiom
#  cd input/mpiom
#  for ivres_oce in ${vres_oce}; do
#    cp -p ${pool_oce}/${res_oce}/${res_oce}${ivres_oce}_INISAL_PHC  ${res_oce}${ivres_oce}_INISAL_PHC
#    cp -p ${pool_oce}/${res_oce}/${res_oce}${ivres_oce}_INITEM_PHC  ${res_oce}${ivres_oce}_INITEM_PHC
#    cp -p ${pool_oce}/${res_oce}/${res_oce}${ivres_oce}_SURSAL_PHC  ${res_oce}${ivres_oce}_SURSAL_PHC
#  done
#  cp -p ${pool_oce}/${res_oce}/${res_oce}_BEK                    ${res_oce}_BEK
#  cp -p ${pool_oce}/${res_oce}/${res_oce}_anta                   ${res_oce}_anta
#  cp -p ${pool_oce}/${res_oce}/${res_oce}_arcgri                 ${res_oce}_arcgri
#  cp -p ${pool_oce}/${res_oce}/${res_oce}_topo                   ${res_oce}_topo
#  cp -p ${pool_oce}/${res_oce}/${res_oce}s.nc                    ${res_oce}s.nc
#  cp -p ${pool_oce}/${res_oce}/${res_oce}u.nc                    ${res_oce}u.nc
#  cp -p ${pool_oce}/${res_oce}/${res_oce}v.nc                    ${res_oce}v.nc
#
#  if [[ "${lcouple}" != ".true." ]]; then
#    cp -p ${pool_oce}/${res_oce}/${res_oce}_GI*_OMIP365 .
#    cp -p ${pool_oce}/runoff_pos .
#    cp -p ${pool_oce}/runoff_obs .
#  fi
#
#  cd ${wrkdir}
#  chmod 644 input/mpiom/*
#  if [[ ${restart_mpiom} != "" ]]; then
#    mkdir -p restart/mpiom
#    cp -p ${restart_mpiom} restart/mpiom/rerun_mpiom.ext
#    chmod 644 restart/mpiom/*
#  fi
#
#  tarfile="${tarfile}_${res_oce}${vres_oce}"
#fi

##-------------------------------------
## HAMOCC input files
##-------------------------------------
#if [[ "$(echo ${cplmod} | grep b)" = "${cplmod}" ]]; then    # hamocc
#
#  mkdir -p input/hamocc
#  chmod -R 755 input/hamocc
#  cd input/hamocc
#  cp -p ${pool_oce}/${res_oce}/${res_oce}_INPDUST.nc  ${res_oce}_INPDUST.nc
#  cp -p ${pool_oce}/${res_oce}/${res_oce}_LUODUST.nc  ${res_oce}_LUODUST.nc
#  cp -p ${pool_oce}/${res_oce}/${res_oce}_MAHOWALDDUST.nc  ${res_oce}_MAHOWALDDUST.nc
#
#  cat >hamocc_sed_level_file <<EOF
#zaxistype : depth_below_sea
#size      : 12
#levels    : 1 4 9 16 25 36 49 64 81 100 121 144
#EOF
#
#  cd ${wrkdir}
#  chmod 644 input/hamocc/*
#  if [[ ${restart_hamocc} != "" ]]; then
#    mkdir -p restart/hamocc
#    cp -p ${restart_hamocc} restart/hamocc/rerun_hamocc.nc
#    chmod 644 restart/hamocc/*
#  fi
#fi

[[ ${cplmod} = s ]] && rm -rf input/echam6
if [[ -d restart ]]; then
  tar cvf ${tarfile}.tar input restart
else
  tar cvf ${tarfile}.tar input
fi
mkdir -p ${pool_cpl}/echamfesom-${cplmod}
mv ${tarfile}.tar ${pool_cpl}/echamfesom-${cplmod}

echo "\nInput tarfile ${tarfile}.tar created and moved to ${pool_cpl}/echamfesom-${cplmod}\n"

exit 0
