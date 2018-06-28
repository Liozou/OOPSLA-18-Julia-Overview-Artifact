# Artifact for _Julia: Dynamism and Performance Reconciled by Design_ (OOPSLA '18)


## Getting Started
- Download the Julia source files from either https://github.com/JuliaLang/julia/releases/tag/v0.6.2 or https://github.com/JuliaLang/julia/tree/v0.6.2. Clone them to your home directory. This artifact is made to support Julia v0.6.2: it may not work with subsequent versions of Julia.
- Merge the contents of the `julia/` folder of the artifact with the one you just created in your home directory.
- Build Julia by using the command `make` with no option in the `julia/` repository located in your home directory. This can take up to a few hours.

The main modifications in the code of the modified files are placed as
```C
//>>> Instrumentation
modified code
//<<< Instrumentation
```
for C code and as
```julia
#>>> Instrumentation
modified code
#<<< Instrumentation
```
for Julia code.

## Step by Step Instructions

This artifact presents our method to
- statically record all the methods defined in a Julia package
- dynamically record all the function calls that appear between two points of a program. This consists in recording the function name, the call site, the called method and the types of each argument to the function.

These combined metrics allow to give all the results exposed and studied in section 6 of the paper.

This artifact also contains the benchmark used for the relative performance evaluation in section 3 of the paper.

### Benchmarking

The Julia installation from this artifact runs much slower than the standard one, because method devirtualization is disabled in order to properly record all the function calls. It is thus not suitable for benchmarking.

To enable method devirtualization, simply uncomment line 2906 of `base/inference.jl`, stating
```julia
inlining_pass!(me)
```
and recompile Julia. This recompilation should take less than fifteen minutes.

### Fine-grain recording of function calls

To record all the function calls between point A and point B of a program:
- at point A, add the line
```julia
ccall(:jl_start_instrumentation, Void, ())
```
- at point B, add the line
```julia
ccall(:jl_end_instrumentation, Void, ())
```
- to interrupt the recording, add the line
```julia
ccall(:jl_stop_instrumentation, Void, ())
```
at the required place. The recording can be resumed with
```julia
ccall(:jl_start_instrumentation, Void, ())
```
- The record will be written on the standard error buffer: you should thus reroute stderr into the file where you want to store the log – this is done on the command line by using
    ```bash
    command 2> LOG_NAME
    ```
This limitation is inherent to our recording method. Note that as a consequence, the log may be polluted by error messages sent by the Julia runtime: these should only appear before and after the actual log, not in the middle of it, so they can easily be removed. This is also one of the reasons why we only kept packages that passed their own test suites to do our analyses, so as not to be polluted by these errors.

The log will consist in call traces separated by empty lines. A call trace has the following structure:
```
:function   (a name)
*callsite_1 (a number)
$method_A   (a tuple of types)
 call_X     (a tuple of types)
val_1X      (the number of times call X has happened at call site 1)
 call_Y
val_1Y
*callsite_2
$method_A
 call_Y
val_2Y
$method_B
 call_Z
val_2Z
...
```

A parser for these logs is the `parse_perf` function, given in `analytics/parse_performance.jl`.

### Recording of package test suites

This artifact modifies the `Pkg.test` function in order to automatically record all the function call traces while running package test suites.
To do so, run
```julia
Pkg.test(PackageName)
```
This will generate four different files in the `logs` folder of your home Julia directory:
- `PackageName.log` is the raw log, whose structure has been described in the last paragraph.
- `dyns/PackageName.dyn` is the parsed version of the log.
- `static/PackageName.static` contains all the methods accessible by the Julia funtime during the tests, regrouped by the function they refine. This information is essentially static, but it is completed by the number of calls and the number of specializations that happened during the tests, which are dynamic values.
- `unk/PackageName.unk` contains the name of the functions that were reported in the log but not in the preceding files. They are not true methods: rather, they are builtin Julia functions that cannot be overloaded. As such, they are out of the scope of our study (they represent less than 10 functions in total).

The last three files are Julia file, which can be imported in Julia with
```julia
obj = load_back(file_path)
```
where `load_back` is defined in `analytics/measure_dispatch`.

### Section 6 figures

###### test
