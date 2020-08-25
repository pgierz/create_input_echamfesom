import crayons
import everett
from loguru import logger

import subprocess

from cli import main
from config import get_config


@main.command()
def compile_jsbach_init_file(config=get_config()):
    """Compiles the jsbach init file program"""
    command_to_run = f"{config('fc')} lala.f90"
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
