# conda recipes for Summit

These are conda recipes for manually creating ppc64le conda packages for packages that conda-forge has yet to be [migrated to support ppc64le builds](https://github.com/regro/cf-scripts/pull/444).

Built packages are currently being pushed to the [omnia](https://anaconda.org/omnia) conda channel.

To use [`omnia` packages](http://www.omnia.md/install/):
```bash
# Add conda-forge and omnia to your channel list
conda config --add channels omnia --add channels conda-forge
# Update to conda-forge versions of packages
conda update --yes --all
```
Then, for example, to install `openmm`:
```
# Install the 'openmm' a package
conda install openmm
```


## Building the packages
```bash
conda build --numpy 1.14 swig fftw3f
CUDA_VERSION="9.2" CUDA_SHORT_VERSION="92" conda build --numpy 1.14 --python 3.6 openmm
anaconda upload /gpfs/alpine/scratch/jchodera1/bip178/miniconda/conda-bld/linux-ppc64le/openmm-*
```


Notes:
```
The following NEW packages will be INSTALLED:

    binutils_impl_linux-ppc64le: 2.31.1-he53550c_1
    binutils_linux-ppc64le:      2.31.1-he53550c_3
    gcc_impl_linux-ppc64le:      8.2.0-he01c8ba_1 
    gcc_linux-ppc64le:           8.2.0-h9f3bcec_3 
    libgcc-ng:                   8.2.0-h822a55f_1 
    libstdcxx-ng:                8.2.0-h822a55f_1 
```