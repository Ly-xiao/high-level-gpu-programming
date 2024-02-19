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



srun ./hello

#srun --job-name=example --account=project_462000456 --partition=standard --reservation=hlgp-gpu-f2024 --time=00:05:00 --nodes=1 --ntasks-per-node=1 --gpus-per-task=1 ./hello

#srun --job-name=example --account=project_462000456 --partition=dev-g --time=00:05:00 --nodes=1 --ntasks-per-node=1 --cpus-per-task=1 --gpus-per-node=1 ./hello
