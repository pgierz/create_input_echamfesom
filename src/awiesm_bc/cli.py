import click
import crayons
from loguru import logger

import sys
import subprocess


@click.group()
def main(args=None):
    """Console script for awiesm_bc"""
    return 0




if __name__ == "__main__":
    sys.exist(main())
