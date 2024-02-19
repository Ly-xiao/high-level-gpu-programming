#!/bin/bash

#SBATCH --job-name=example

#SBATCH --account=project_462000456

#SBATCH --partition=standard-g

#SBATCH --reservation=hlgp-gpu-f2024

#SBATCH --time=00:05:00

#SBATCH --nodes=1

#SBATCH --ntasks-per-node=1

#SBATCH --cpus-per-task=1

#SBATCH --gpus-per-node=1


srun usm
