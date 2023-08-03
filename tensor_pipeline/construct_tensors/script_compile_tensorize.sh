#!/bin/bash

# DESCRIPTION: This bash script is to execute compile_tensors.m which compiles
#              the output of the driver_tensorize.m function called from
#              script_tensorize.sh The compile_tensors.m function only reorganizes
#              how files are saved, so it can be run locally. It is used to
#              ensure the correct file format later on however, so it should
#              be run either on GreatLakes or locally.
#
# TODO:        Before running the script, there are 3 fields that should
#              change with every job submission:
#              1. job name
#              2. output file
#              3. parameters passed to compile_tensors
#              4. set values of i on line 24 of compile_tensors to set which sets of
#                 tensors are being compiled.

#SBATCH --job-name=Compile-Tensors
#SBATCH --mail-user=jpic@umich.edu
#SBATCH --mail-type=BEGIN,END
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=1
#SBATCH --mem=32G
#SBATCH --time=1:00:00
#SBATCH --account=kayvan1
#SBATCH --partition=standard
#SBATCH --output=/nfs/turbo/med-kayvan-lab/Projects/DoD_Multimodal/Code/Joshua/datasets/CWR/more_epsilons_T/%x-%j.log

# The application(s) to execute along with its input arguments and options:
matlab -nodisplay -r "compile_tensors(string('CWR'), string('more_epsilons_T')); exit"


