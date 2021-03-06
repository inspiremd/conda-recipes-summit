CMAKE_FLAGS="-DCMAKE_INSTALL_PREFIX=$PREFIX -DBUILD_TESTING=OFF -DOPENMM_BUILD_CUDA_TESTS=OFF"

# Ensure we build a release
CMAKE_FLAGS+=" -DCMAKE_BUILD_TYPE=Release"

if [[ "$OSTYPE" == "linux-gnu" ]]; then
    #
    # For Docker build
    #

    # JDC test
    #echo "PATH: $PATH"
    #env

    #CMAKE_FLAGS+=" -DCMAKE_C_COMPILER=clang -DCMAKE_CXX_COMPILER=clang++"

    # Hack to work around path issues
    #cp $PREFIX/../_build_env/lib/libfftw3f*.so $PREFIX/lib
    CMAKE_FLAGS+=" -DCMAKE_LIBRARY_PATH=$PREFIX/../lib:/usr/lib64"

    # CFLAGS
    #export MINIMAL_CFLAGS="-g -O3 -I$PREFIX/../_build_env/include/ -L$PREFIX/../_build_env/lib"
    #export MINIMAL_CFLAGS="-g -O3 -I$BUILD_PREFIX/include/ -L$BUILD_PREFIX/lib -L/usr/lib64 -L/usr/lib64/nvidia"
    #CMAKE_FLAGS+=" -DCMAKE_CXX_LINK_FLAGS=-Wl,-rpath=/usr/lib64:/usr/lib64/nvidia"

    #export MINIMAL_CFLAGS="-g -O3 -I$BUILD_PREFIX/include/ -L$BUILD_PREFIX/lib"
    export MINIMAL_CFLAGS="-g -O3 -I$BUILD_PREFIX/include/ -L$BUILD_PREFIX/lib -L/usr/lib64 -L/usr/lib64/nvidia"
    export CFLAGS="$MINIMAL_CFLAGS"
    export CXXFLAGS="$MINIMAL_CFLAGS"
    export LDFLAGS="$LDPATHFLAGS"

    export LD_LIBRARY_PATH="/usr/lib64:/usr/lib64/nvidia:$LD_LIBRARY_PATH"

    echo `$CC --version`
    echo `$CXX --version`
    #export CC="$BUILD_PREFIX/bin/powerpc64le-conda_cos7-linux-gnu-gcc"
    #export CXX="$BUILD_PREFIX/bin/powerpc64le-conda_cos7-linux-gnu-g++"
    CMAKE_FLAGS+=" -DCMAKE_C_COMPILER=$CC -DCMAKE_CXX_COMPILER=$CXX"
    CMAKE_FLAGS+=" -DCMAKE_C_COMPILER_AR=$BUILD_PREFIX/bin/powerpc64le-conda_cos7-linux-gnu-ar"
    CMAKE_FLAGS+=" -DCMAKE_C_COMPILER_RANLIB=$BUILD_PREFIX/bin/powerpc64le-conda_cos7-linux-gnu-ranlib"
    CMAKE_FLAGS+=" -DCMAKE_CXX_COMPILER_AR=$BUILD_PREFIX/bin/powerpc64le-conda_cos7-linux-gnu-ar"
    CMAKE_FLAGS+=" -DCMAKE_CXX_COMPILER_RANLIB=$BUILD_PREFIX/bin/powerpc64le-conda_cos7-linux-gnu-ranlib"

    # OpenMM build configuration
    #CUDA_PATH="/usr/local/cuda"
    CUDA_PATH=$CUDAPATH
    CMAKE_FLAGS+=" -DCUDA_TOOLKIT_ROOT_DIR=${CUDA_PATH}/"
    # AMD APP SDK 3.0 OpenCL
    #CMAKE_FLAGS+=" -DOPENCL_INCLUDE_DIR=${CUDA_PATH}/include/"
    #CMAKE_FLAGS+=" -DOPENCL_LIBRARY=${CUDA_PATH}/lib64/libOpenCL.so"
    # CUDA OpenCL
    #CMAKE_FLAGS+=" -DOPENCL_INCLUDE_DIR=${CUDA_PATH}/include/"
    #CMAKE_FLAGS+=" -DOPENCL_LIBRARY=${CUDA_PATH}/lib64/libOpenCL.so"
    # gcc from devtoolset-2
    #CMAKE_FLAGS+=" -DCMAKE_CXX_LINK_FLAGS=-Wl,-rpath,/opt/rh/devtoolset-2/root/usr/lib64" # JDC test
    #CMAKE_FLAGS+=" -DCMAKE_CXX_FLAGS=--gcc-toolchain=/opt/rh/devtoolset-2/root/usr/"
    echo ""
    echo "DEBUG:"    
    echo $CMAKE_FLAGS
elif [[ "$OSTYPE" == "darwin"* ]]; then
    # conda-build MACOSX_DEPLOYMENT_TARGET must be exported as an environment variable to override 10.7 default
    # cc: https://github.com/conda/conda-build/pull/1561
    export MACOSX_DEPLOYMENT_TARGET="10.9"
    CMAKE_FLAGS+=" -DCMAKE_C_COMPILER=clang -DCMAKE_CXX_COMPILER=clang++"
    CMAKE_FLAGS+=" -DCMAKE_OSX_DEPLOYMENT_TARGET=${MACOSX_DEPLOYMENT_TARGET}"
    CMAKE_FLAGS+=" -DCUDA_TOOLKIT_ROOT_DIR=/Developer/NVIDIA/CUDA-${CUDA_VERSION}"
    CMAKE_FLAGS+=" -DCMAKE_OSX_SYSROOT=/Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX${MACOSX_DEPLOYMENT_TARGET}.sdk"
fi

# Generate API docs
CMAKE_FLAGS+=" -DOPENMM_GENERATE_API_DOCS=ON"

# Set location for FFTW3 on both linux and mac
CMAKE_FLAGS+=" -DFFTW_INCLUDES=$PREFIX/include"
if [[ "$OSTYPE" == "linux-gnu" ]]; then
    CMAKE_FLAGS+=" -DFFTW_LIBRARY=$BUILD_PREFIX/lib/libfftw3f.so"
    CMAKE_FLAGS+=" -DFFTW_THREADS_LIBRARY=$BUILD_PREFIX/lib/libfftw3f_threads.so"
elif [[ "$OSTYPE" == "darwin"* ]]; then
    CMAKE_FLAGS+=" -DFFTW_LIBRARY=$PREFIX/lib/libfftw3f.dylib"
    CMAKE_FLAGS+=" -DFFTW_THREADS_LIBRARY=$PREFIX/lib/libfftw3f_threads.dylib"
fi

# Build in subdirectory and install.
mkdir build
cd build
cmake .. $CMAKE_FLAGS
echo $CPU_COUNT
make -j$CPU_COUNT all

# PythonInstall uses the gcc/g++ 4.2.1 that anaconda was built with, so we can't add extraneous unrecognized compiler arguments.
#export CXXFLAGS="$MINIMAL_CFLAGS"
#export LDFLAGS="$LDPATHFLAGS"
#export SHLIB_LDFLAGS="$LDPATHFLAGS"

#make -j$CPU_COUNT install PythonInstall

make -j$CPU_COUNT install 
export OPENMM_INCLUDE_PATH=$PREFIX/include
export OPENMM_LIB_PATH=$PREFIX/lib
cd python
python setup.py build
python setup.py install --prefix=$PREFIX

# Clean up paths for API docs.
#mkdir openmm-docs
#mv $PREFIX/docs/* openmm-docs
#mv openmm-docs $PREFIX/docs/openmm

#if [[ "$OSTYPE" == "linux-gnu" ]]; then
#    # Add GLIBC_2.14 for pdflatex
#    export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/opt/glibc-2.14/lib
#fi

# DEBUG: Needed for latest sphinx
#locale -a
#export LC_ALL=C
#locale -a

# Build PDF manuals
#make -j$CPU_COUNT sphinxpdf
#mv sphinx-docs/userguide/latex/*.pdf $PREFIX/docs/openmm/
#mv sphinx-docs/developerguide/latex/*.pdf $PREFIX/docs/openmm/

# Put examples into an appropriate subdirectory.
mkdir $PREFIX/share/openmm/
mv $PREFIX/examples $PREFIX/share/openmm/
