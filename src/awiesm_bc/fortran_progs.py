import crayons
from loguru import logger

import pkgutil
import subprocess
import tempfile

from awiesm_bc.cli import main
from awiesm_bc.config import get_config


def _get_fortran_program(prog_name):
    """Gets a string representation of the ``FORTRAN`` program specified by
    ``prog_name``, assuming it is under the ``fortran`` subdirectory in
    the main ``src`` directory."""
    return pkgutil.get_data("awiesm_bc", f"../fortran/{prog_name}")


@main.command()
def compile_jsbach_init_file():
    """Compiles the jsbach init file program"""
    config = get_config()
    jsbach_init_file_str = _get_fortran_program("jsbach_init_file.f90")
    jsbach_init_file = tempfile.NamedTemporaryFile()
    jsbach_init_file.write(jsbach_init_file_str)
    print(jsbach_init_file)
    import pdb; pdb.set_trace()
    command_to_run = f"{config('fc', namespace='jsbach_init_file')} {jsbach_init_file.name}"
    # command_to_run = "lalala exit 3"
    logger.info("--> Compiling pre-requisite program: jsbach_init_file.f90")
    logger.debug(command_to_run)
    try:
        subprocess.check_output(command_to_run, shell=True)
    except subprocess.CalledProcessError as e:
        error_message = e.output.decode()
        logger.error("ERROR! Sorry...")
        if error_message:
            logger.error(f"{error_message}")
        return e.returncode
    else:
        logger.success("...done!")
        return 0


# PG For testing:
if __name__ == "__main__":
    compile_jsbach_init_file()
