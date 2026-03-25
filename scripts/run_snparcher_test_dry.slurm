#!/bin/bash
#SBATCH -J coca_test
#SBATCH -o coca_test_%j.out
#SBATCH -e coca_test_%j.err
#SBATCH -p test
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=1
#SBATCH -t 01:30:00
#SBATCH --mem=4G
#SBATCH --mail-type=END,FAIL
#SBATCH --mail-user=dawsonwhite@g.harvard.edu

# Load conda
CONDA_BASE=$(conda info --base)
source $CONDA_BASE/etc/profile.d/conda.sh
conda activate snparcher

# Go to run directory (IMPORTANT)
cd /n/netscratch/davis_lab/Everyone/dwhite/cocawgs/snparcher_runs/run1

# Dry run
snakemake \
  -s /n/home08/dwhite/software/snpArcher/workflow/Snakefile \
  --configfile /n/home08/dwhite/cocawgs-snparcher/config/config.yaml \
  --profile /n/home08/dwhite/cocawgs-snparcher/workflow-profiles/default \
  -n -p
