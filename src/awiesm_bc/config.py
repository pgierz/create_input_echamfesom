#!/usr/bin/env python3
"""
AWIESM Boundary Condition Configuration
========================================

Configuration for the ``awiesm_bc`` tool follows the XDG standard. The
configuration should be stored in a YAML file.

You can use the function write_default_config to generate a configuration file
with the hard-coded defaults. Command line access for this command is available
via::

    $ awiesm_bc --write-default-config

The default configuration will be written to
``${XDG_CONFIG_HOME}/awiesm_bc/awiesm_bc.yaml``

Order of Precedence
-------------------

Configuration is loaded in the following order:

   1. Command line
   2. Config file thats name is declared on the command line.
   3. Environment vars
   4. Local config file (if exists)
   5. Global config file (if exists)
   6. Hard-coded defaults in the code
"""
from everett.component import RequiredConfigMixin, ConfigOptions
from everett.ext.yamlfile import ConfigYamlEnv
from everett.manager import ConfigManager, ConfigOSEnv
import xdg.BaseDirectory

import pathlib
import os
import subprocess


CONFIG_FILES = [
    directory + "/awiesm_bc/awiesm_bc.yml" for directory in xdg.BaseDirectory.xdg_config_dirs
]
"""
List of files where configuration information is searched for
"""

def _has_prog(prog):
    """Checks if ``prog`` is available via ``$ which <prog>``"""
    try:
        subprocess.check_output(f"which {prog}", shell=True)
        return True
    except subprocess.CalledProcessError:
        return False


def _has_nc_config():
    """True/False if the system has nc-config"""
    return _has_prog("nc-config")


def _default_netcdf_fc(default="gfortran"):
    """
    Provides the default ``FORTRAN`` compiler for ``NetCDF`` if nc-config is
    installed, otherwise falls back to the default. If nothing is specified,
    the default is ``gfortran``

    Parameters
    ----------
    default : str
        Which compiler to fall back to

    Returns
    -------
    str :
        The compiler that should be the default for ``NetCDF``
    """
    if _has_nc_config():
        ret_val = subprocess.check_output("nc-config --fc", shell=True)
        return ret_val.decode().strip()
    else:
        return default


class AppConfig(RequiredConfigMixin):
    """Contains the defaults for the awiesm_bc configuration"""

    required_config = ConfigOptions()
    required_config.add_option(
        "debug", parser=bool, default="false", doc="Switch debug mode on and off."
    )
    required_config.add_option(
        "fc",
        default=_default_netcdf_fc(),
        doc="Which ``FORTRAN`` compiler to use for the ``jsbach_init_file`` program",
        namespace="jsbach_init_file",
    )


def get_config(config_file=None):
    """Loads the configuration

    Loads either the user supplied configuration, the configuration in the XDG
    path, or the default config. Configuration may be given incompletely, so if
    you only supply the color (for example), other configuration values are
    taken from the defaults. The user can also supply a configuration stored in
    a yaml file as an argument to this function, this takes first priority.

    Parameters
    ----------
    config_file : str or Path
        Which config to load

    Returns
    -------
    config : dict
        The configuration to use

    """

    environments = [
        # Look in OS process environment first
        ConfigOSEnv(),
        # Look in YAML files in order specified (CONFIG_FILES is a list)
        ConfigYamlEnv(CONFIG_FILES),
    ]
    if config_file:
        # Add the user supplied configuration file to the front of the list if
        # it was given:
        environments.insert(0, ConfigYamlEnv(config_file))
    manager = ConfigManager(
        # Specify one or more configuration environments in
        # the order they should be checked
        environments=environments,
    )

    # Apply the configuration class to the configuration manager
    # so that it handles option properties like defaults, parsers,
    # documentation, and so on.
    return manager.with_options(AppConfig())


def write_default_config():
    # TODO: BROKEN!
    """
    Creates a default configuration file under the XDG Base Directory
    nmldiff/nmldiff.yaml
    """
    config_path = pathlib.Path(xdg.BaseDirectory.xdg_config_home) / "awiesm_bc"
    config_file = config_path / DEFAULT_CONFIG_FILENAME
    if not os.path.isdir(config_path):
        os.makedirs(config_path)

    if not os.path.isfile(config_file):
        # TODO: write file
        pass
