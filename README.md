# conda recipes for Summit

These are conda recipes for manually creating ppc64le conda packages for packages that conda-forge has yet to be [migrated to support ppc64le builds](https://github.com/regro/cf-scripts/pull/444).

Built packages are currently being pushed to the [omnia](https://anaconda.org/omnia) conda channel.

## Installing on Summit

First, install `miniconda` from your `$MEMBER_WORK` directory (`/gpfs/alpine/scratch/$USER/$PROJECT/`):
```bash
wget https://repo.continuum.io/miniconda/Miniconda3-latest-Linux-ppc64le.sh
bash Miniconda3-latest-Linux-ppc64le.sh -b -p miniconda
export PATH=$MEMBER_WORK/miniconda/bin:$PATH
```
The `ppc64le` packages have been uploaded to the [`omnia`](https://anaconda.org/omnia) and [`conda-forge`](https://anaconda.org/conda-forge) channels:
```bash
# Add conda-forge and omnia to your channel list
conda config --add channels omnia --add channels conda-forge
# Update to conda-forge versions of packages
conda update --yes --all
```
The `openmm` packge is built from OpenMM development snapshot [`81bad1b`](https://github.com/pandegroup/openmm/tree/81bad1bc142d4b1fc286473528b454a3a8e26197) and uploaded to the [`omnia-dev`](https://anaconda.org/omnia-dev/openmm/files) channel:
```bash
# Install the 'openmm' 7.4.0 dev package for ppc64le 
conda install --yes -c omnia-dev/label/cuda92 openmm
```
Currently, only the CUDA 9.2 build has been uploaded.

## Building the packages

If you need to rebuild the packages from scratch, start an interactive job:
```bash
bsub -W 2:00 -nnodes 1 -P bip178 -Is /bin/bash
```
Then build the dependencies:
```bash
# Build openmm dependencies not yet built for ppc64le by conda-forge
conda build --numpy 1.14 swig fftw3f doxygen
# Upload the to omnia
anaconda upload -u omnia /gpfs/alpine/scratch/jchodera1/bip178/miniconda/conda-bld/linux-ppc64le/{swig,fftw,doxygen}*
# Build OpenMM for cuda 9.2
module unload cuda
module load cuda/9.2.148
CUDA_VERSION="9.2" CUDA_SHORT_VERSION="92" conda build --numpy 1.14 --python 2.7 openmm
CUDA_VERSION="9.2" CUDA_SHORT_VERSION="92" conda build --numpy 1.14 --python 3.6 openmm
CUDA_VERSION="9.2" CUDA_SHORT_VERSION="92" conda build --numpy 1.14 --python 3.7 openmm
# Upload OpenMM packages to conda-dev under desired labels
anaconda upload -u omnia-dev -l main -l cuda92 /gpfs/alpine/scratch/jchodera1/bip178/miniconda/conda-bld/linux-ppc64le/openmm-*
```

See https://github.com/pandegroup/openmm/issues/2258 for more details.

