import click
# TODO: import crayons
# TODO: import loguru

import sys
import subprocess


@click.group()
def main(args=None):
    """Console script for awiesm_bc"""
    return 0


@main.command()
def compile_jsbach_init_file(args=None):
    """Compiles the jsbach init file program"""
    command_to_run = "echo gfortran lala.f90"
    command_to_run = "lalala exit 3"
    print("\t--> Compiling pre-requisite program: jsbach_init_file.f90")
    try:
        subprocess.check_output(command_to_run, shell=True)
    except subprocess.CalledProcessError as e:
        error_message = e.output.decode()
        print("\t    ERROR! Sorry...")
        if error_message:
            print(f"\t    {error_message}")
        return e.returncode
    else:
        print("\t    SUCCESS!")


if __name__ == "__main__":
    sys.exist(main())
