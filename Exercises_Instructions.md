# General exercise instructions

## Getting the materials

All course materials, slides and hands-out are available in the github repository. They can be downloaded with the command

```
https://github.com/csc-training/higher-level-gpu-programming.git
```

If you have a GitHub account you can also **Fork** this repository and clone
then your fork. That way you can easily commit and push your own solutions
to exercises.

### Repository structure

The exercise assignments are provided in various `README.md`s.
For most of the exercises, some skeleton codes are provided as starting point. In addition, all of the exercises have exemplary full codes 
(that can be compiled and run) in the `solutions` folder. **Note that these are 
seldom the only or even the best way to solve the problem.**

## Using supercomputers

Exercises can be carried out using the [LUMI](https://docs.lumi-supercomputer.eu/)  supercomputer, [Mahti](https://docs.csc.fi/computing/systems-mahti/), and [Intel DevCloud](https://console.cloud.intel.com/).

 ![](docs/img/cluster_diagram.jpeg)

LUMI can be accessed via ssh using the provided username and ssh key pair:
```
ssh -i <path-to-private-key> <username>@lumi.csc.fi
```
Mahti can be accessed via ssh using the provided username and CSC password:

```
ssh  <username>@mahti.csc.fi
```
The Intel DevCloud can be acces via the [web interface](https://console.cloud.intel.com/).

### Disk area 

The  (computing and storage)  resources can be accessed on on supercomputers via project-based allocation system, where users are granted access based on the specific needs and goals of their projects. Running applications and storage area are directly linked ot this projects. For this event we have been granted access to the training `project_2008874` on Mahti and `project_462000456` on LUMI. 

All the exercises in the supercomputers have to be carried out in the**scratch** disk area. The name of the scratch directory can be queried with the commands `csc-workspaces` on Mahti and `lumi-workspaces` onLUMI. As the base directory is shared between members of the project, you should create your own
directory:

on Mahti
```
cd /scratch/project_2008874
mkdir -p $USER
cd $USER
```

on LUMI
```
cd /scratch/project_2008874
mkdir -p $USER
cd $USER
```
The `scratch` area has quota of 1-2TB per project. More than enough for the training. In addition to this other areas are disks areas available. The `projappl/project_xyz` area is faster and can be used for storing the project applications (should not be used for data storage) and on LUMI the so called `flash/project_xyz` disk area can be used for IO intensive runs. 

### Editors

For editing program source files you can use e.g. *nano* editor:

```
nano prog.f90
```
(`^` in nano's shortcuts refer to **Ctrl** key, *i.e.* in order to save file and exit editor press `Ctrl+X`)
Also other popular editors such as emacs and vim are available. 

## Compilation

Mahti and LUMI have several programming environments. For training, we recommend that you use the two SYCL implementations:

### Intel oneAPI compilers
In order to use the intel SYCL compiler one has to  set the environment varibles first:

on Mahti:
```
. /projappl/project_2008874/intel/oneapi/setvars.sh --include-intel-llvm
```

on LUMI:
```
. /projappl/project_462000456/intel/oneapi/setvars.sh --include-intel-llvm
```

After this one can load other modules that might be needed for compiling the codes.
### AdaptiveCpp

on Mahti:
```
/projappl/project_2008874/AdaptiveCpp/bin/acpp -O3 -L/appl/spack/v017/install-tree/gcc-8.5.0/gcc-11.2.0-zshp2k/lib64 enumerate_devices.cpp
```

on LUMI:
```
 /projappl/project_462000456/AdaptiveCpp/bin/acpp -O3  enumerate_devices.cpp
```

### MPI

Compilation of the MPI programs can be performed with the `CC`, `cc`, or `ftn`
wrapper commands:
```
CC -o my_mpi_exe test.cpp
```
or
```
cc -o my_mpi_exe test.c
```
or
```
ftn -o my_mpi_exe test.f90
```

The wrapper commands include automatically all the flags needed for building
MPI programs.

### OpenMP (threading with CPUs)

Pure OpenMP (as well as serial) programs can also be compiled with the `CC`,
`cc`, and `ftn` wrapper commands. OpenMP is enabled with the
`-fopenmp` flag:
```
CC -o my_exe test.cpp -fopenmp
```
or
```
cc -o my_exe test.c -fopenmp
```
or
```
ftn -o my_exe test.f90 -fopenmp
```

When code uses also MPI, the wrapper commands include automatically all the flags needed for
building MPI programs.

### HDF5

In order to use HDF5 in CSC supercomputers, you need the load the HDF5 module with MPI I/O support.
The appropriate module in **Lumi** is
```
module load cray-hdf5-parallel/1.12.2.1
```

No special flags are needed for compiling and linking, the compiler wrappers take care of them automatically.

Usage in local workstation may vary.

### OpenMP offloading

On **Lumi**, the following modules are required:

```bash
module load LUMI/22.08
module load partition/G 
module load cce/15.0.1
module load rocm/5.3.3
```

On **Lumi**, to compile your program, use
```bash
CC -fopenmp <source.cpp>
```


### HIP

Use the following modules :

```bash
module load LUMI/22.08
module load partition/G
module load cce/15.0.1
module load rocm/5.3.3
```

To compile your program, use:
```bash
CC -xhip <source.cpp>
```
### HIPFORT 
The following modules are required:
```bash

module load LUMI/22.08
module load partition/G
module load cce/15.0.1
module load rocm/5.3.3
```

Because the default `HIPFORT` installation only supports gfortran,  we use a custom installation  prepared in the summer school project. This package provide Fortran modules compatible with the Cray Fortran compiler as well as direct use of hipfort with the Fortran Cray Compiler wrapper (ftn). 

The package was installed via:
```bash
git clone https://github.com/ROCmSoftwarePlatform/hipfort.git
cd hipfort;
mkdir build;
cd build;
cmake -DHIPFORT_INSTALL_DIR=<path-to>/HIPFORT -DHIPFORT_COMPILER_FLAGS="-ffree -eZ" -DHIPFORT_COMPILER=ftn -DHIPFORT_AR=${CRAY_BINUTILS_BIN_X86_64}/ar -DHIPFORT_RANLIB=${CRAY_BINUTILS_BIN_X86_64}/ranlib  ..
make -j 64 
make install
```

We will use the Cray 'ftn' compiler wrapper as you would do to compile any fortran code plus some additional flags:
```bash
export HIPFORT_HOME=/project/project_465000536/appl/HIPFORT
ftn -I$HIPFORT_HOME/include/hipfort/amdgcn "-DHIPFORT_ARCH=\"amd\"" -L$HIPFORT_HOME/lib -lhipfort-amdgcn $LIB_FLAGS -c <fortran_code>.f90 
CC -xhip -c <hip_kernels>.cpp
ftn  -I$HIPFORT_HOME/include/hipfort/amdgcn "-DHIPFORT_ARCH=\"amd\"" -L$HIPFORT_HOME/lib -lhipfort-amdgcn $LIB_FLAGS -o main <fortran_code>.o hip_kernels.o
```
This option gives enough flexibility for calling HIP libraries from Fortran or for a mix of OpenMP/OpenACC offloading to GPUs and HIP kernels/libraries.

## Running in LUMI

### Pure MPI

Programs need to be executed via the batch job system. Simple job running with 4 MPI tasks can be submitted with the following batch job script:
```
#!/bin/bash
#SBATCH --job-name=example
#SBATCH --account=project_465000536
#SBATCH --partition=standard
#SBATCH --reservation=summerschool_standard
#SBATCH --time=00:05:00
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=4
#SBATCH --cpus-per-task=1  

srun my_mpi_exe
```

Save the script *e.g.* as `job.sh` and submit it with `sbatch job.sh`.
The output of job will be in file `slurm-xxxxx.out`. You can check the status of your jobs with `squeue -u $USER` and kill possible hanging applications with
`scancel JOBID`.

The reservation `summerschool` is available during the course days and it
is accessible only with the training user accounts.

### Pure OpenMP

For pure OpenMP programs one should use only one node and one MPI task per nodesingle tasks and specify the number of cores reserved
for threading with `--cpus-per-task`:
```
#!/bin/bash
#SBATCH --job-name=example
#SBATCH --account=project_465000536
#SBATCH --partition=standard
#SBATCH --reservation=summerschool_standard
#SBATCH --time=00:05:00
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=1
#SBATCH --cpus-per-task=4

# Set the number of threads based on --cpus-per-task
export OMP_NUM_THREADS=$SLURM_CPUS_PER_TASK
srun my_omp_exe
```

### Hybrid MPI+OpenMP

For hybrid MPI+OpenMP programs it is recommended to specify explicitly number of nodes, number of
MPI tasks per node (pure OpenMP programs as special case with one node and one task per node),
and number of cores reserved for threading. The number of nodes is specified with `--nodes`
(for most of the exercises you should use only a single node), number of MPI tasks **per node**
with `--ntasks-per-node`, and number of cores reserved for threading with `--cpus-per-task`.
The actual number of threads is specified with `OMP_NUM_THREADS` environment variable.
Simple job running with 4 MPI tasks and 4 OpenMP threads per MPI task can be submitted with
the following batch job script:
```
#!/bin/bash
#SBATCH --job-name=example
#SBATCH --account=project_465000536
#SBATCH --partition=standard
#SBATCH --reservation=summerschool_standard
#SBATCH --time=00:05:00
#SBATCH --nodes=2
#SBATCH --ntasks-per-node=32
#SBATCH --cpus-per-task=4
# Set the number of threads based on --cpus-per-task
export OMP_NUM_THREADS=$SLURM_CPUS_PER_TASK
srun my_exe
```


### GPU programs

When running GPU programs, few changes need to made to the batch job
script. The `partition` is are now different, and one must also request explicitly given number of GPUs per node with the
`--gpus-per-node=8` option. As an example, in order to use a
single GPU with single MPI task and a single thread use:
```
#!/bin/bash
#SBATCH --job-name=example
#SBATCH --account=project_465000536
#SBATCH --partition=standard-g
#SBATCH --reservation=summerschool_standard-g
#SBATCH --gpus-per-node=8
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --time=00:05:00

srun my_gpu_exe
```

## Running in local workstation

In most MPI implementations parallel program can be started with the `mpiexec` launcher:
```
mpiexec -n 4 ./my_mpi_exe
```

In most workstations, programs build with OpenMP use as many threads as there are CPU cores
(note that this might include also "logical" cores with simultaneous multithreading). A pure OpenMP
program can be normally started with specific number of threads with
```bash
OMP_NUM_THREADS=4 ./my_exe
```
and a hybrid MPI+OpenMP program e.g. with
```
OMP_NUM_THREADS=4 mpiexec -n 2 ./my_exe
```

## Debugging

See [the MPI debugging exercise](mpi/debugging),
[CSC user guide](https://docs.csc.fi/computing/debugging/), and
[LUMI documentation](https://docs.lumi-supercomputer.eu/development/)
for possible debugging options.

## Performance analysis with TAU and Omniperf
```
# Create installation directory
mkdir -p .../appl/tau
cd .../appl/tau

# Download TAU
wget https://www.cs.uoregon.edu/research/tau/tau_releases/tau-2.32.tar.gz
tar xvf tau-2.32.tar.gz
mv tau-2.32 2.32

# Go to TAU directory
cd 2.32

./configure -bfd=download -otf=download -unwind=download -dwarf=download -iowrapper -cc=cc -c++=CC -fortran=ftn -pthread -mpi -phiprof -papi=/opt/cray/pe/papi/6.0.0.15/
make -j 64

./configure -bfd=download -otf=download -unwind=download -dwarf=download -iowrapper -cc=cc -c++=CC -fortran=ftn -pthread -mpi -papi=/opt/cray/pe/papi/6.0.0.15/ -rocm=/appl/lumi/SW/LUMI-22.08/G/EB/rocm/5.3.3/ -rocprofiler=/appl/lumi/SW/LUMI-22.08/G/EB/rocm/5.3.3/rocprofiler
make -j 64

./configure -bfd=download -otf=download -unwind=download -dwarf=download -iowrapper -cc=cc -c++=CC -fortran=ftn -pthread -mpi -papi=/opt/cray/pe/papi/6.0.0.15/ -rocm=/appl/lumi/SW/LUMI-22.08/G/EB/rocm/5.3.3/ -roctracer=/appl/lumi/SW/LUMI-22.08/G/EB/rocm/5.3.3/roctracer
make -j 64
```

`TAU` and `Omniperf` can be used to do performance analysis. 
In order to use TAU one only has to load the modules needed to run the application be ran and set the paths to the TAU install folder:
```
export TAU=/project/project_465000536/appl/tau/2.32/craycnl
export PATH=$TAU/bin:$PATH
```
Profiling mpi code:
```
srun --cpus-per-task=1 --account=project_465000536 --nodes=1 --ntasks-per-node=4 --partition=standard --time=00:05:00 --reservation=summerschool_standard tau_exec -ebs ./mandelbrot
```
In order to to see the `paraprof` in browser use `vnc`:
```
module load lumi-vnc
start-vnc
```
Visualize:
```
paraprof
```
Tracing:

```
export TAU_TRACE=1
srun --cpus-per-task=1 --account=project_465000536 --nodes=1 --ntasks-per-node=4 --partition=standard --time=00:05:00 --reservation=summerschool_standard tau_exec -ebs ./mandelbrot
tau_treemerge.pl
tau_trace2json tau.trc tau.edf -chrome -ignoreatomic -o app.json
```

Copy `app.json`  to local computer, open ui.perfett.dev and then load the `app.json` file.
## Omniperf
```
https://amdresearch.github.io/omniperf/installation.html#client-side-installation
```
In order to use omniperf load the following modules:
```
module use /project/project_465000536/Omni/omniperf/modulefiles
module load omniperf
module load cray-python
srun -p standard-g --gpus 1 -N 1 -n 1 -c 1 --time=00:30:00 --account=project_465000536 omniperf profile -n workload_xy --roof-only --kernel-names  -- ./heat_hip
omniperf analyze -p workloads/workload_xy/mi200/ > analyse_xy.txt
```
In additition to this one has to load the usual modules for running GPUs. Keep in mind the the above installation was done with `rocm/5.3.3`.
It is useful add to the compilation of the application to be analysed the follwing `-g -gdwarf-4`.

More information about TAU can be found in [TAU User Documentation](https://www.cs.uoregon.edu/research/tau/docs/newguide/), while for Omniperf at [Omniperf User Documentation](https://github.com/AMDResearch/omniperf)
