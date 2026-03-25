## 2026-03-16

### FASTQ data transfer to FASRC (rsync)

Raw FASTQ files were transferred from local storage to the FASRC scratch filesystem using `rsync`.

Command used:

```bash
rsync -av --progress --partial /Volumes/Coca\ WGS/cocawgs2022/fastq/ \
dwhite@login.rc.fas.harvard.edu:/n/netscratch/davis_lab/Everyone/dwhite/cocawgs/all_cocawgs_fastqs/
rsync -av --progress --partial /Volumes/Coca\ WGS/cocawgs2023/fastq/ \
dwhite@login.rc.fas.harvard.edu:/n/netscratch/davis_lab/Everyone/dwhite/cocawgs/all_cocawgs_fastqs/
rsync -av --progress --partial /Volumes/Coca\ WGS/cocawgs2024/fastq/ \
dwhite@login.rc.fas.harvard.edu:/n/netscratch/davis_lab/Everyone/dwhite/cocawgs/all_cocawgs_fastqs/
```

Notes on rsync usage
-a (archive mode): preserves file structure, timestamps, and permissions
-v: verbose output
--progress: displays transfer progress for each file
--partial: allows resuming interrupted transfers

All FASTQ files are stored in:
/n/netscratch/davis_lab/Everyone/dwhite/cocawgs/all_cocawgs_fastqs/


## 2026-03-24

### Git / reproducibility setup
- Created analysis directory on FASRC:
  `/n/home08/dwhite/cocawgs-snparcher`
- Initialized local git repository with:
  `git init`
- Added initial project files:
  - `.gitignore`
  - `README.md`
  - `envs/snparcher.yaml`
  - `notes/NOTES.md`
  - `scripts/run_snparcher.slurm`
- Made initial commit:
  `Initial commit: snpArcher analysis framework (configs, scripts, env)`

### GitHub setup
- Confirmed SSH authentication to GitHub is working from FASRC.
- Set git remote for GitHub repo:
  `git@github.com:Erythroxylum/cocawgs-snparcher.git`
- Renamed default branch from `master` to `main`.
- Resolved mismatch with remote history caused by GitHub license file.
- Successfully pushed local repository to GitHub.

### Repository purpose
This repository will serve as the reproducibility/provenance repo for Coca WGS analyses:
- versioned configs
- sample metadata
- SLURM scripts
- environment files
- analysis notes
- future phylogeographic analysis code and documentation

### Integration of existing snpArcher configuration
Located an existing working directory:
`/n/home08/dwhite/snparcher-coca`

This directory contained:
- workflow configuration files
- sample sheet
- SLURM configuration
- pipeline execution script

These files were identified as analysis-specific configuration and therefore moved into the version-controlled analysis repository:

`/n/home08/dwhite/cocawgs-snparcher/legacy/snparcher_v1_run/`

Rationale:
- ensure configuration and metadata are tracked in git
- centralize reproducible inputs to the workflow
- avoid maintaining untracked analysis directories in home

### snpArcher workflow setup

Cloned the upstream `snpArcher` workflow repository into a dedicated software directory in home:

```bash
mkdir -p /n/home08/dwhite/software
cd /n/home08/dwhite/software
git clone https://github.com/harvardinformatics/snpArcher.git
```

### Samplesheet

Added many H2 and H3 samples that matched WGS data to increase coverage in target capture loci.
Also added grac_745 with no WGS.

full run: samplesheet_cocawgs-2026-v1-s544.csv
test: samplesheet_cocawgs-2026-v1-s46.csv

The snpArcher sample sheet is maintained in the analysis repository:
`/n/home08/dwhite/cocawgs-snparcher/config/`

To verify fastq file paths:
```bash
cut -d',' -f3 samplesheet_cocawgs-2026-v1-s46.csv | tail -n +2 | tr ';' '\n' | xargs -I{} ls {} | grep 'cannot'
```

For each analysis run, the sample sheet will be copied or symlinked into the corresponding scratch run directory.

### snpArcher configuration setup

Copied the default configuration file from the upstream snpArcher repository into the analysis repository:

Source:
`/n/home08/dwhite/software/snpArcher/config/config.yaml`

Destination:
`/n/home08/dwhite/cocawgs-snparcher/config/config.yaml`

This file will serve as the project-specific configuration for Coca WGS analyses.

#### changes to cocawgs-snparcher/config/config.yaml

samples: "config/samplesheet_cocawgs-2026-v1-s46.csv"
genome name: "ENN-GCA_029891385.1"
genome source: "GCA_029891385.1"
mindepth: 1


### changes to SLURM Configuration Setup

The upstream default profile was located at:

`/n/home08/dwhite/software/snpArcher/workflow-profiles/default/config.yaml`

A project-specific copy should be maintained in the analysis repository so that cluster submission settings are version controlled independently of the upstream workflow code.

`/n/home08/dwhite/cocawgs-snparcher/workflow-profiles/default/config.yaml`

#### changes
  tmpdir: ./tmp # Replace with an absolute path to force a custom temp directory for the whole run.
  slurm_partition: "sapphire" or "temp"
  # slurm_account: # Same as sbatch -A. Not all clusters use this.
  runtime: 720 # In minutes

#### modify threads for fastp, bwa_map, dedup

set-resources: #uncomment, delete spaces
   fastp:
     mem_mb: attempt * 10000

   bwa_map: # uncomment 
     mem_mb: attempt * 16000 #uncomment and change to 10k

   dedup:
     mem_mb: attempt * 16000

   merge_bams:
     mem_mb: attempt * 16000

   bam2gvcf: # HaplotypeCaller
     mem_mb: attempt * 16000
     mem_mb_reduced: (attempt * 16000)
     runtime: 1000

   DB2vcf: # GenotypeGVCFs
     mem_mb: attempt * 16000
     mem_mb_reduced: (attempt * 16000) * 0.9 
     runtime: 1000

### Modify fastp: Edits to files such as `workflow/rules/fastq.smk` are workflow code changes and should be treated as modifications to the snpArcher workflow itself, not merely project configuration.
 
snpArcher/workflow/rules/fastq.smk

            --trim_front1=5 \
            --trim_front2=5 \
            --cut_mean_quality=20 \
            --cut_front \
            --cut_tail \
            --trim_poly_g \
            --trim_poly_x \
            --length_required=25 \

### Create TMPDIR

mkdir -p /n/netscratch/davis_lab/Everyone/dwhite/cocawgs/snparcher_runs/run1/tmp

### First snpArcher dry-run command

Configured the initial dry run to use:
- the upstream snpArcher Snakefile
- the project-specific Coca WGS config
- the project-specific SLURM workflow profile

Command used:

```bash
snakemake \
  -s /n/home08/dwhite/software/snpArcher/workflow/Snakefile \
  --configfile /n/home08/dwhite/cocawgs-snparcher/config/config.yaml \
  --profile /n/home08/dwhite/cocawgs-snparcher/workflow-profiles/default \
  -n -p
```

This setup keeps:

workflow code in the upstream snpArcher clone
analysis configuration in the version-controlled project repo
cluster submission settings in the project-specific workflow profile

The dry run is executed from the scratch working directory for run1.

### Testing snpArcher branch for mixed SRR + FASTQ inputs

After reporting the mixed-input error (`sample_id` containing both `srr` and `fastq` entries), Tim Sackton provided a test branch with a proposed fix.

From the upstream snpArcher clone:

```bash
cd /n/home08/dwhite/software/snpArcher
git fetch origin
git switch --track origin/codex/mixed-srr-fastq-inputs
```

This branch is intended to allow combined srr and fastq inputs for the same biological sample.
