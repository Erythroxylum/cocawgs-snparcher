#!/bin/bash
#SBATCH -J coca400
#SBATCH -o outcoca
#SBATCH -e errcoca
#SBATCH -p intermediate
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=1
#SBATCH -t 9000
#SBATCH --mem=10000

CONDA_BASE=$(conda info --base)
source $CONDA_BASE/etc/profile.d/conda.sh
conda activate snparcher
snakemake --snakefile workflow/Snakefile --workflow-profile ./profiles/slurm 
