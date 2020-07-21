# Tutorial:

To generate ECHAM6 and JSBACH input files from a new FESOM mesh, follow these steps:

1) Compute the CDO grid description for A FESOM grid. See [here](https://gitlab.dkrz.de/FESOM/fesom2/blob/master/docs/convert_grid_to_nc.md)
2) Interpolate the orography (using e.g. ETOPO 1 or your reconstruction)
3) Make sure the program `jsbach_init_file` compiles correctly. It will be re-built during the main program.
4) The main program is `create_input_echamfesom.ksh`. Read it carefully to know what it is doing!! Of particular importance is:

    a) At the top of the file, make a new case statement with your specific resolution. This should have the mesh path and mesh griddes correctly set.
    
    b) Also make a case statement with your specific land/sea fraction. This is a number close to 0.5.
    
    c) Dynveg on/off? It appears as if this is done multiple times for different dynveg options

