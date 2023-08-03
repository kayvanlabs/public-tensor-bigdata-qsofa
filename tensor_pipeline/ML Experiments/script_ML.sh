#!/bin/bash

# DESCRIPTION: This bash script is to execute driver_experiments.m which
#              trains models on the feature vectors output from 
#              driver_tensor_decomp.m
#
# TODO:        Before running the script, there are 3 fields that should
#              change with every job submission:
#              1. job name
#              2. output file
#              3. parameters passed to driver_experiments
# 

#SBATCH --job-name=ML-EXPERIMENTS
#SBATCH --mail-user=jpic@umich.edu
#SBATCH --mail-type=BEGIN,END
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=32
#SBATCH --mem=60G
#SBATCH --time=20:00:00
#SBATCH --account=kayvan1
#SBATCH --partition=standard
#SBATCH --output=/nfs/turbo/med-kayvan-lab/Projects/DoD_Multimodal/Code/Joshua/datasets/EMG/epsilon_bounds/upper_bounds/1/logspaced/%x-%j.log
#SBATCH --array=1-12

# The application(s) to execute along with its input arguments and options: $SLURM_ARRAY_TASK_ID
matlab -nodisplay -r "driver_ML(string('EMG'), string('epsilon_bounds/upper_bounds/1/logspaced'), $SLURM_ARRAY_TASK_ID, 45, 0); exit"


