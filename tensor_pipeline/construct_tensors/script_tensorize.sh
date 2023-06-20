#!/bin/bash

# DESCRIPTION: This bash script is to execute driver_tensorize.m which
#              constructs tensors from multilead signals. It runs as an
#              array job, where the job id is the number of windows in the
#              tensors being constructed.
#
# TODO:        Before running the script, there are 3 fields that should
#              change with every job submission:
#              1. job name
#              2. output file
#              3. parameters passed to driver_tensorize
#              4. the number of windows (set as SBATCH --array param)
#              5. check the time and memory allocated based on your data requirements

#SBATCH --job-name=Tensorize
#SBATCH --mail-user=jpic@umich.edu
#SBATCH --mail-type=BEGIN,END
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=32
#SBATCH --mem=50G
#SBATCH --time=6:00:00
#SBATCH --account=kayvan1
#SBATCH --partition=standard
#SBATCH --output=/nfs/turbo/med-kayvan-lab/Projects/DoD_Multimodal/Code/Joshua/datasets/EMG/epsilon_bounds/upper_bounds/1/logspaced/%x-%j.log
#SBATCH --array=2-10

# The application(s) to execute along with its input arguments and options:
matlab -nodisplay -r "driver_tensorize(string('EMG'), string('epsilon_bounds/upper_bounds/1/logspaced/'), string('TS'), $SLURM_ARRAY_TASK_ID); exit"


