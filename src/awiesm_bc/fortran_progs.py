from loguru import logger

import os
import pkgutil
import subprocess
import xdg.BaseDirectory

from awiesm_bc.cli import main
from awiesm_bc.config import get_config


def _get_fortran_program(prog_name):
    """
    Gets a string representation of the ``FORTRAN`` program specified by
    ``prog_name``, assuming it is under the ``src/fortran`` subdir.
    """
    return pkgutil.get_data("awiesm_bc", f"../fortran/{prog_name}").decode()


@main.command()
def compile_jsbach_init_file():
    """Compiles the jsbach init file program"""
    logger.info("--> Compiling pre-requisite program: jsbach_init_file.f90")
    config = get_config()
    # This gets a string representation of the jsbach_init_file.f90 program,
    # packaged together with the rest of the stuff here, similar to how
    # open(<filename>).read() would do.
    jsbach_init_file_str = _get_fortran_program("jsbach_init_file.f90")
    # Now make a folder to put it:
    os.makedirs(f"{xdg.BaseDirectory.get_runtime_dir()}/awiesm_bc", exist_ok=True)
    # And actually write the program to disk...
    # FIXME(PG): Probably, there is a less dumb way to do this...
    jsbach_init_file = open(
        f"{xdg.BaseDirectory.get_runtime_dir()}/awiesm_bc/jsbach_init_file.f90",
        mode="w",
    )
    jsbach_init_file.write(jsbach_init_file_str)
    # Figure out if the user has super special choices for the fortran
    # compiler, flibs, and fflags
    fc = config("fc", namespace="jsbach_init_file")
    flibs = config("flibs", namespace="jsbach_init_file")
    fflags = config("fflags", namespace="jsbach_init_file")
    # Tell the world what you will try to compile:
    command_to_run = f"{fc} {fflags} {flibs} {jsbach_init_file.name} -o {jsbach_init_file.name.replace('.f90', '')}"
    logger.debug(command_to_run)
    try:
        # Compile the dude:
        subprocess.check_output(command_to_run, shell=True)
    except subprocess.CalledProcessError as e:
        # Something fucked up. Tell us what went wrong:
        error_message = e.output.decode()
        logger.error("ERROR! Sorry...")
        if error_message:
            logger.error(f"{error_message}")
        return e.returncode
    else:
        # Nothing fucked up. Give back the path to the program you just compiled...
        logger.success("...done!")
        return f"{jsbach_init_file.name.replace('.f90', '')}"


# PG For testing:
if __name__ == "__main__":
    compile_jsbach_init_file()
