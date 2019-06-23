# conda recipes for Summit

These are conda recipes for manually creating ppc64le conda packages for packages that conda-forge has yet to be [migrated to support ppc64le builds](https://github.com/regro/cf-scripts/pull/444).

Built packages are currently being pushed to the [omnia](https://anaconda.org/omnia) conda channel.

## Installing on Summit

If you need help setting up your `~/.bash_profile`, see [these notes](https://github.com/inspiremd/HOWTO/blob/master/Running%20YANK%20on%20summit.md).

First, install `miniconda` from your `$MEMBER_WORK` directory (`/gpfs/alpine/scratch/$USER/$PROJECT/`):
```bash
wget https://repo.continuum.io/miniconda/Miniconda3-latest-Linux-ppc64le.sh
bash Miniconda3-latest-Linux-ppc64le.sh -b -p miniconda
# Initialize your ~/.bash_profile
conda init bash
```
The `ppc64le` packages have been uploaded to the [`omnia`](https://anaconda.org/omnia) and [`conda-forge`](https://anaconda.org/conda-forge) channels:
```bash
# Add conda-forge and omnia to your channel list
conda config --add channels omnia --add channels conda-forge
# Update to conda-forge versions of packages
conda update --yes --all
```
The `openmm` packge is built from OpenMM development snapshot [`d5905f8`](https://github.com/pandegroup/openmm/commit/d5905f8) and uploaded to the [`omnia-dev`](https://anaconda.org/omnia-dev/openmm/files) channel:
```bash
# Create a new environment named 'openmm'
conda create -n openmm python==3.7
# Activate it
conda activate openmm
# Install the 'openmm' 7.4.0 dev package for ppc64le into this environment
conda install --yes -c omnia-dev/label/cuda101 openmm
```
Currently, CUDA 9.2 and 10.1 builds have been uploaded.

## Testing openmm

```bash
# Log into a batch node
bsub -W 2:00 -nnodes 1 -P bip178 -alloc_flags gpudefault -Is /bin/bash

# Make sure to activate conda environment
# TODO: Is there a way we can make sure the `~/.bash_profile` is executed on log in?
source ~/.bash_profile
conda activate

# Install the CUDA and appropriate MPI modules:
module unload cuda
module load cuda/10.1.105 gcc/8.1.1 spectrum-mpi/10.2.0.10-20181214

# Run the benchmark via jsrun requesting
# one resource set (-n 1), one MPI process (-a 1), one core (-c 1), one GPU (-g 1)
cd $MINICONDA/share/openmm/examples
jsrun --smpiargs="none" -n 1 -a 1 -c 1 -g 1 python benchmark.py --platform=CUDA --test=pme --precision=mixed --seconds=30 --heavy-hydrogens
```
I see the following benchmarks on Summit:
```
Platform: CUDA
Precision: mixed

Test: pme (cutoff=0.9)
Step Size: 5 fs
Integrated 48894 steps in 28.5644 seconds
739.46 ns/day
```

## Building the packages

If you need to rebuild the packages from scratch, start an interactive job:
```bash
bsub -W 2:00 -nnodes 1 -P bip178 -alloc_flags gpudefault -Is /bin/bash
source ~/.bash_profile # TODO: Can we get this to automatically execute when bash starts?
conda activate
```
Install `conda-build`:
```bash
conda install --yes conda-build conda-verify anaconda-client
```
Then build the dependencies:
```bash
# Build openmm dependencies not yet built for ppc64le by conda-forge
conda build --numpy 1.14 --python 3.6 swig fftw3f doxygen pymbar parmed
conda build --numpy 1.14 --python 3.7 swig fftw3f doxygen pymbar parmed
# Upload the to omnia
anaconda upload -u omnia /gpfs/alpine/scratch/jchodera1/bip178/miniconda/conda-bld/linux-ppc64le/{swig,fftw,doxygen,pymbar}*

# Clean up
conda clean -tipsy

# Build OpenMM for cuda 9.2
module unload cuda
module load cuda/9.2.148
CUDA_VERSION="9.2" CUDA_SHORT_VERSION="92" conda build --numpy 1.14 --python 2.7 openmm
CUDA_VERSION="9.2" CUDA_SHORT_VERSION="92" conda build --numpy 1.14 --python 3.6 openmm
CUDA_VERSION="9.2" CUDA_SHORT_VERSION="92" conda build --numpy 1.14 --python 3.7 openmm
# Upload OpenMM packages to conda-dev under desired labels
anaconda upload -u omnia-dev --force -l main -l cuda92 /gpfs/alpine/scratch/jchodera1/bip178/miniconda/conda-bld/linux-ppc64le/openmm-*

# Clean up
conda clean -tipsy

# Build OpenMM for cuda 10.1
module unload cuda
module load cuda/10.1.105
CUDA_VERSION="10.1" CUDA_SHORT_VERSION="101" conda build --numpy 1.14 --python 2.7 openmm
CUDA_VERSION="10.1" CUDA_SHORT_VERSION="101" conda build --numpy 1.14 --python 3.6 openmm
CUDA_VERSION="10.1" CUDA_SHORT_VERSION="101" conda build --numpy 1.14 --python 3.7 openmm
anaconda upload -u omnia-dev --force -l cuda101 /gpfs/alpine/scratch/jchodera1/bip178/miniconda/conda-bld/linux-ppc64le/openmm-*
```

See https://github.com/pandegroup/openmm/issues/2258 for more details.

