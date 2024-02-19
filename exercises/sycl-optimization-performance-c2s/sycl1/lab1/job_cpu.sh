#!/bin/bash

#SBATCH --job-name=example

#SBATCH --account=project_462000456

#SBATCH --partition=small

##SBATCH --reservation=hlgp-cpu-f2024

#SBATCH --time=00:05:00

#SBATCH --nodes=1

#SBATCH --ntasks-per-node=1

#SBATCH --cpus-per-task=1



srun cpu_sample
