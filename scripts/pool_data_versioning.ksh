#!/bin/ksh
#------------------------------------------------------------------------------
# script to handle jsbach input file versioning in the pool directories
#
#   /pool/data/JSBACH/<res>              - corresponds to revision r0001
#                                          should not be used any longer
#   /pool/data/JSBACH/input/<rev>/<res>  - files of revision <rev>
#
# Included in the versioning are all files read by jsbach at run time, not
# the files needed to generate jsbach initial files.
#
# This script adds a new revision <rev> and handels the linking.
#  - The new revision consists of soft links to the real files.
# The actual changes from the current revision to the previous revision have
# to be done manually (i.e. exchange of some files; adding/removing files)
#
# Veronika Gayler, February 2014
#------------------------------------------------------------------------------
set -ex

rev=r0007
reslist="HD 05 T31 T63 T127 T255"
pooljsb=/pool/data/JSBACH

make_new_revision=true    # generate new revision directory with soft links
link_latest=false         # link main pool directory to latest revision


cd ${pooljsb}

if [[ ${make_new_revision} = true ]]; then
  mkdir -p input
  mkdir -p input/${rev}

  # generate the first revision as copy from general pool directory

  if [[ ${rev} = "r0001" ]]; then
    for res in ${reslist}; do
      mkdir input/${rev}/${res}
      filelist=$(ls ${res})
      for file in ${filelist}; do
        cp -pr ${res}/${file} input/${rev}/${res}
      done
    done
  else

  # generate new revision as copy from previous revision

    prev=$(ls input | tail -2 | head -1)     # previous revision
    for res in ${reslist}; do
      mkdir input/${rev}/${res}
      filelist=$(ls input/${prev}/${res})
      for file in ${filelist}; do
        if [[ -L input/${prev}/${res}/${file} ]]; then
          target=$(ls -l input/${prev}/${res}/${file} | cut -f2 -d\>)
          ln -s ${target} input/${rev}/${res}
        else
          ln -s ${pooljsb}/input/${prev}/${res}/${file} input/${rev}/${res}
        fi
      done
    done
  fi
fi

# link default directory to latest revision

if [[ ${link_latest} = true ]]; then
  echo "jsbach files outside version control should not be changed"
  exit
  for res in ${reslist}; do
    ln -sf  ${pooljsb}/input/${rev}/${res}/* ${res}
  done
fi
