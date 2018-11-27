#!/bin/ksh
#------------------------------------------------------------------------------
# fill missing values in vegmax_6_T63.lola (veg_ratio_max)
#
# Used to generate JSBACH initial files for the LGM 
# Veronika Gayler, December 2010
#------------------------------------------------------------------------------
set -e

# convert to extra (to be able to use the cdos)
ext copy vegmax_6_T63.lola vegmax_6_T63.ext

# convert to netcdf and set the grid
#   the lola grid is shifted by 180 deg in comparison to standard T63. This
#   does not matter as the array is re-converted to lola in the end. But the
#   netcdf file should not be used! 

cdo -f nc setgrid,t63grid -setmissval,0 vegmax_6_T63.ext vegmax_6_T63.miss.nc

# do the extrapolation
cdo fillmiss vegmax_6_T63.miss.nc vegmax_6_T63.filled.nc

# re-convert to lola
cdo -f ext copy vegmax_6_T63.filled.nc vegmax_6_T63.filled.ext
lola griddes vegmax_6_T63.lola > lolagrid
lola copy vegmax_6_T63.filled.ext vegmax_6_T63.filled.lola < lolagrid

# remove temporary files
rm lolagrid vegmax_6_T63.ext vegmax_6_T63.filled.ext vegmax_6_T63.miss.nc \
   vegmax_6_T63.filled.nc

