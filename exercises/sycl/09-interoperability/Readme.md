# Using 3rd party libraries. 
Third-party libraries are essential for GPU programming, offering optimized functions and algorithms tailored for specific tasks while abstracting low-level hardware details. This abstraction enables developers to focus on algorithm design and application development, enhancing productivity and efficiency.

For Intel hardware, the [Intel® oneAPI Math Kernel Library](https://www.intel.com/content/www/us/en/developer/tools/oneapi/onemkl.html) (oneMKL) provides a comprehensive set of low-level routines for math operations. It is highly optimized and extensively parallelized, supporting Intel CPUs and GPUs, with a SYCL interface for integration into SYCL codes.

Nvidia hardware users can leverage the [CUDA toolkit](https://developer.nvidia.com/cuda-toolkit), offering a suite of highly optimized libraries such as cuBLAS and cuFFT. These libraries enhance performance for various computational tasks on Nvidia GPUs.

Similarly, for AMD hardware, the [ROCm/HIP](https://rocm.docs.amd.com/projects/HIP/en/latest/) libraries provide optimized routines for GPU-accelerated computing, enabling efficient utilization of AMD GPUs.

At the moment there is no unified interface to select automatically the needed library based on the device with which each queue is associated. Furthermore some libraries such as cu/hipBlas or cu/hipFFT require a gpu stream submit the work in an asynchronous way and integrate the call with previous ans subsenquent kernels. However in general a SYCL queue is not necesseraly associated with given stream. The SYCL standard defines the queue behaviour, but it is up to the `SYCL implementation` how that is mapped to the `cuda/hip stream`. 

## Matrix-Matrix multiplication example
Take the example of dense matrix-matrix multimplication. We saw the [memory optimization exercise](../04-matrix-matrix-mul/) how we can improve the performance. This direct programming is acceptable if the operation is only a very small percentage of the total computating time or if only a few cases (system sizes) are needed and optimization is done for those specific cases. 

For more general cases an optimized library is needed and it depends on the target hardware with wich the queue is associated.

### Intel Hardware with oneMKL and oneAPI
The oneMKL libraries have SYCL interface. They take as argument the SYCL queues and they support both buffers and USM pointers. In some way this is the easiestway. To multiply two matrices just use this:
```
    //# transpose status of matrices for oneMKL
    oneapi::mkl::transpose transA = oneapi::mkl::transpose::nontrans, transB = oneapi::mkl::transpose::nontrans;
    oneapi::mkl::blas::gemm(q, transA, transB, N, N, N, alpha, dev_b, N, dev_a, N, beta, dev_c, N);
```
Where `dev_a` and `dev_b` contain the input data and the results is saved in `dev_c`. These pointers are allocated via USM calls. This call is asynchronous and if the data is needed imediatly the `q.wait()`  call is needed. The SYCL queue which is given as argument needs to be associated with a CPU or an Intel GPU (spir targets). 
In addition to this the proper header needs to be included:
```
#include "oneapi/mkl.hpp"
```

Compiling the code requires some extra flags for linking to the MKL library:
```
-I$MKLROOT/include  -L$MKLROOT/lib/intel64/  -lmkl_sycl -lmkl_core  -lmkl_sequential -lmkl_intel_ilp64
```
Where `MKLROOT` is an environment variable which is set during the initial set up of the oneAPI.
### Nvidia and AMD hardware
In the case non-Intel hardware the specific libraries need to be called. For Nvidia GPUs we use cuBlas, while for AMD hipBlas. Calling directly this library  depends on the SYCL implementation. 

#### Using oneAPI with `cuBlas` 
If you are lucky someone set the [mkl interfaces](https://oneapi-src.github.io/oneMKL/create_new_backend.html) or they are already supported in the [oneMKL interfaces]([interfaces](https://github.com/oneapi-src/oneMKL/tree/develop)). Then the oneMKL calls will call directly the cuda/hip libraries when the cuda/hip backend is enabled. Otherwise we the use `host_task` method to enqueue a libray call on a specific queue:
```
  q.submit([&](handler &h) {
     h.host_task([=](sycl::interop_handle ih) {
       // Set the correct cuda context & stream
       cuCtxSetCurrent(ih.get_native_context<backend::ext_oneapi_cuda>());
       auto cuStream = ih.get_native_queue<backend::ext_oneapi_cuda>();
       cublasSetStream(handle, cuStream);

       // Call generalised matrix-matrix multiply
       CHECK_ERROR(cublasSgemm(handle, CUBLAS_OP_N, CUBLAS_OP_N, N,N,
                               N, &alpha, dev_a, N, dev_b, N, &beta,
                               dev_c, N));
       cuStreamSynchronize(cuStream);
     });
   }).wait();
```
This option is functionally correct, but due to the way the `host_task` is designed, this means that all work before the `ccuBlas` call needs to be finished before the actually call. And then also note the `cuStreamSynchronize()`  call in the `host_task` which means that the program waits for the work to be done before continuing. 

### Using AdaptiveCpp
The alternative to the `host_task` is the `hipSYCL_enqueue_custom_operation()`. As the name suggests this is only available in the AdaptiveCpp (formerly known as hipsycl) implementation. Below is an example:

```
q.submit([&](handler &cgh) {
     cgh.hipSYCL_enqueue_custom_operation([=](sycl::interop_handle &ih) {
       // Set the correct  stream
       auto cuStream = ih.get_native_queue<sycl::backend::cuda>();
       cublasSetStream(handle, cuStream);
       // Call generalised matrix-matrix multiply
       CHECK_ERROR(cublasSgemm(handle, CUBLAS_OP_N, CUBLAS_OP_N, N,N,
                               N, &alpha, dev_a, N, dev_b, N, &beta,
                               dev_c, N));
     });
   }).wait();
``` 
This method allows to enqueue into the SYCL queue the work done by calling an external library. The `cuda/hip stream` information can be extracted from an `in-order` queue via the `get_native_queue()` method. Using this one can sumbit kernels on a queue, make an asychronous call to cuBlas, and continue the work with the results by submitting more kernels to the same queue. This equivalent to submitting work to the same cuda/hip stream.

### Integrating the different approches into the same code. 
Integrating different approaches into the same codebase can be challenging due to portability concerns. Conditional compilation based on compilation flags can be used to selectively include relevant parts of the code for specific hardware targets. This approach allows maintaining a single codebase while supporting multiple hardware configurations.

We start with the headers:
```
#if MKL_LIB
#include "oneapi/mkl.hpp"  //# oneMKL DPC++ interface
#endif

#if CUBLAS 
// cuda interface
#include <cublas_v2.h>
#include <cuda.h>
```
When compiling for using oneMKL on Intel hardware we add the extra flag `-DMKL_LIB`, this will result in compiling on the line whic includes the oneMKL header. However if the application will be executed on Nvidia GPUs and using cuBlas the option `-DCUBLAS` is needed. Further more into the code a condition compilation can be done to select between `host_task` and `hipSYCL_enqueue_custom_operation`:
```

#if MKL_LIB // uses mkl blas    
        
    //# transpose status of matrices for oneMKL
    oneapi::mkl::transpose transA = oneapi::mkl::transpose::nontrans;
    oneapi::mkl::transpose transB = oneapi::mkl::transpose::nontrans;
  
        
    //# Submit MKL library call to execute on device
    blas::gemm(q, transA, transB, N, N, N, alpha, dev_b, N, dev_a, N, beta, dev_c, N); 

    q.wait(); 
#endif  

#if CUBLAS

// Create cublas handle
  cublasHandle_t handle;
  CHECK_ERROR(cublasCreate(&handle));

#if ACPP
std::cout << "\n"<< "Running with ACPP interoperability. \n";
q.submit([&](handler &cgh) {
     cgh.hipSYCL_enqueue_custom_operation([=](sycl::interop_handle &ih) {
       // Set the correct  stream
       auto cuStream = ih.get_native_queue<sycl::backend::cuda>();
       cublasSetStream(handle, cuStream);
       // Call generalised matrix-matrix multiply
       // Call generalised matrix-matrix multiply
       CHECK_ERROR(cublasSgemm(handle, CUBLAS_OP_N, CUBLAS_OP_N, N,N,
                               N, &alpha, dev_a, N, dev_b, N, &beta,
                               dev_c, N));
     });
   }).wait();
#endif

#if DPCPP  
  std::cout << "\n"<< "Warning!!! " << " \n" << " The DPC++ & CUDA \n relies on the number of assumptions:\n in-order queues,\n no event- or buffer-based dependencies, \n no frequent switching between multiple devices \n stars aligning properly.\n\n"; 
  q.submit([&](handler &h) {
     h.host_task([=](sycl::interop_handle ih) {
       // Set the correct cuda context & stream
       cuCtxSetCurrent(ih.get_native_context<backend::ext_oneapi_cuda>());
       auto cuStream = ih.get_native_queue<backend::ext_oneapi_cuda>();
       cublasSetStream(handle, cuStream);

       // Call generalised matrix-matrix multiply
       CHECK_ERROR(cublasSgemm(handle, CUBLAS_OP_N, CUBLAS_OP_N, N,N,
                               N, &alpha, dev_a, N, dev_b, N, &beta,
                               dev_c, N));
       cuStreamSynchronize(cuStream);
     });
   }).wait();
#endif

#endif
```
This looks ugly and kind of bits the purpose of using SYCL, but if it is only a small part of the whole code it is preferable to having 3-5 different version of the same application written for different devices (CPU, Intel GPU, FPGA, Nvidia GPU, AMD GPU, and so on).

For a complete example implementation, refer to the provided  [code](gemm_mkl_cublas_usm.cpp). Note in the comments at the beginning of the code the instructions for compiling the code for different situations.

## Compilation
Here are the complete compilation options for the various cases.

#### OneAPI with `oneMKL`

```
icpx -std=c++17 -fuse-ld=lld -O3 -fsycl -fsycl-targets=spir64_x86_64 -I$MKLROOT/include  -L$MKLROOT/lib/intel64/  -lmkl_sycl -lmkl_core  -lmkl_sequential -lmkl_intel_ilp64   -DMKL_LIB gemm_mkl_cublas_usm.cpp
``` 

#### OneAPI with `cuBlas`
```
icpx -std=c++17 -fuse-ld=lld -isystem $CUDA_HOME/include/  -DCUBLAS -DDPCPP -std=c++17 -O3 -fsycl -fsycl-targets=nvptx64-nvidia-cuda -Xsycl-target-backend=nvptx64-nvidia-cuda --cuda-gpu-arch=sm_80  -L$CUDA_HOME/lib64/ -lcublas -lcudart -lcuda
```
#### AdaptiveCpp with `cuBlas`

```
 /projappl/project_2008874/AdaptiveCpp/bin/acpp -fuse-ld=lld -O3 -DCUBLAS -DACPP -I$CUDA_HOME/include/ -L$CUDA_HOME/lib64/ -lcublas -lcudart -lcuda
```
