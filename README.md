Scripts for generating ECHAM6 and JSBACH initial files and land/sea masks adapted to the FESOM ocean grid
======

The scripts are based on the original scripts by Veronika Gayler (MPI-M), copied from /pf/zmaw/m220053/mpiesm-1.2.01-release/contrib/initial_tarfiles as of November 2018. The parts relating to the MPIOM model were changed to support unstructured ocean grids as used by FESOM. The scripts use the cdo operator "remapycon" heavily, therefore CDO grid description files for the FESOM ocean grids are needed to produce the input files for ECHAM6 and JSBACH. These can be created with the spheRlab package (see below), maintained by Helge Goessling (AWI). 

The FESOM model is developed and supported by researchers at the Alfred Wegener Institute, Helmholtz Centre for Polar and Marine Research (AWI), in Bremerhaven, Germany.

Documentation
=============

**Load the following modules on Mistral @ DKRZ:**

- module load cdo (loaded by default now)
- module load nco (for ncatted)
- module load nag (for the Fortran compiler nagfor)

[Basic tutorial](/docs/README.md) **TODO**

[Compute CDO grid description for a FESOM grid](https://gitlab.dkrz.de/FESOM/fesom2/blob/master/docs/convert_grid_to_nc.md)

To be added
===========

- [x] Add optimized `slm_fractions` -other than 0.5- for every FESOM grid. Assuming that the FESOM land/sea distribution is the truth, the target land area should be close to the value implied by the ocean grid. We can add the values from the previous script that was not under version control.

References
==========

Details about why this is done and an example how an adapted land/sea mask will look like:

* Rackow, T. (2014), An unstructured multi-resolution global climate model:
coupling, mean state and climate variability, p.37ff and Fig. 2.1 in https://elib.suub.uni-bremen.de/edocs/00104415-1.pdf [click](https://elib.suub.uni-bremen.de/edocs/00104415-1.pdf)

Analysis of model runs with ECHAM-FESOM where the adaptation has been performed:

* Sidorenko, D., Rackow, T., Jung, T., Semmler, T., Barbi, D., Danilov, S., Dethloff, K., Dorn, W., Fieg, K., Goessling, H. F., Handorf, D., Harig, S., Hiller, W., Juricke, S., Losch, M., Schröter, J., Sein, D. V., & Wang, Q. (2014), Towards multi-resolution global climate modeling with ECHAM6-FESOM. Part I: model formulation and mean climate. Clim. Dyn., 44, 757–780, doi:10.1007/s00382-014-2290-6
