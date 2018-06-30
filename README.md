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
- statically record all the methods and types defined in a Julia package
- dynamically record all the function calls that appear between two points of a program. This consists in recording the function name, the call site, the called method and the types of each argument to the function.

These combined metrics allow to give all the results exposed and studied in section 6 of the paper.

This artifact also contains the benchmark used for the relative performance evaluation in section 3 of the paper.

All the paths to file detailed below implicitly root in the `~/julia/` directory where Julia is installed.

### Launching Julia

The Julia REPL (read-eval-print loop) can be launched by simply executing the command `julia` in a console. Similarly, a Julia file `a.jl` can be executed with `julia a.jl`.

Installing a package can be done by executing the Julia command
```julia
Pkg.add("PackageName")
```
`DataStreams`, `Lazy` and `BackpropNeuralNet` are examples of light packages whose test suites do not take too much time to run.

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
Pkg.test("PackageName")
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

### Analyses reproduction

The following section explains how to reproduce the results detailed in the "Julia in practice" section of our paper.

##### Data collection

Once a number of packages have been tested and their `.log`, `.dyn` and `.static` have been written to disk in the `logs/` folder, the precise metrics can be automatically collected by uncommenting the last line of `analytics/collect_data.jl` and executing the file. The result is stored in the `logs/data/` folder. Leaving the last line commented allows to load the functions from the file without launching the data collecting process.

Two directories are also created, `logs/static_soft/` and `logs/static_strict/` which contain `.static` files analogous to those in `logs/static/`. They correspond to the functions that passed either the _strict_ or the _soft_ elimination, as defined in the paper.

The `logs/data/` folder itself is subdivided into five different subfolders:
- `function`: dynamic data collected on functions that were not generated by the compiler nor anonymous
- `nonsinglefunction`: refines the precedent class by only keeping functions with at least two methods.
- `static`: static data collected on all functions not generated by the compiler nor anonymous.
- `static_strict`: refines the `static` data with strict elimination.
- `static_soft`: refines the `static` data with soft elimination.

Each of the produced files has a name of the form "source.txt" where `source` is the name of the function from `analytics/collect_data.jl` that generated the data.
The files themselves are composed of lines starting with `PackageName:` followed by the relevant data for the given package. Refer to the documentation of each generating function for more details about the data.

Many relevant metrics can be obtained by merging the data from different packages (using either strict or soft elimination). The functions from `analytics/combine_data.jl` retrieve data from the `logs/data/` folder and process the combined results for various metrics, such as the number of methods per function for instance.

##### Benchmarking

The instrumented Julia installation from this artifact runs much slower than the standard one, mostly because method devirtualization is disabled in order to properly record all the function calls. It is thus not suitable for benchmarking.

To perform benchmarking with the original Julia performance, the modifications from the artifact must be removed, using the line commands
```bash
$ git checkout *; make
```
from the Julia installation directory.
The recompilation should take less than fifteen minutes.

The different optimization cuts observed in figure "Optimization and performance" can be reproduced with the following settings:
- to run Julia with no optimization caused by LLVM, simply run
```bash
julia -O0
```
from the command line.
- to disable type inference, add a
```C
return NULL;
```
at the very beginning of the definition of `jl_type_infer` in `src/gf.c`, line 236, and recompile. This recompilation should take less than a minute.
- to disable method devirtualization, comment out line 2905 of `base/inference.jl` stating
```julia
inlining_pass!(me)
```
and recompile Julia. This recompilation should take less than fifteen minutes.

Don't forget to undo the previous modification between each step to specifically benchmark with one of the features disabled.

## Benchmarks

Benchmark source code for Julia, untyped Julia, JavaScript, C, and Python is included as part of the artifact, along with
our execution harness. The VM image contains their source, but is not configured to execute them.

## Prerequisites

The following prerequisites are required to run the benchmarks:

* **Python 3.5.3 or later**
* **Node.js v8.11.1 or later**
* **Julia 0.6.2**
* **gcc 6.3.0 or later**

Node dependencies are in the package-lock.json file inside the jsshootout folder.

## Organization

Benchmarks reside within the `benchmarks` folder, which contains both the implementations and the runner infrastructure.
Execution is via the makefile at the top level, which both compiles and runs the benchmarks on demand. The folders serve
the following purposes:

* `benchmark_defns` defining benchmark sizes;
* `cshootout` for C benchmarks
* `jlnoty-shootout` for untyped versions of Julia benchmarks that had types originally
* `jlshootout` for Julia benchmarks with all original type annotations
* `jsshooutout` for Javascript benchmarks
* `pyshootout` for Python benchmarks
* `results` for the data in the figure as well as the scripts to generate the figure from the paper.

## Running

Each language has its own benchmark target, defaulting to the Julia benchmarks ran on the full problem size. Available targets are:

* `run_jl_benchmarks` (default) for running the typed Julia benchmarks;
* `run_jl_benchmakrs_noty` for untyped versions of typed Julia benchmarks;
* `run_py_benchmarks` for Python benchmarks;
* `run_js_benchmarks` for JavaScript benchmarks;
* `run_c_benchmarks` for C benchmarks.

The benchmarks, from the Programming Language Benchmark Game, are parameterized over probelm sizes defined in `benchmark_defns`.
Numbers reported in the paper come from `full_size.sh`, but `small_size.sh` can be used while testing the environment for quick
execution. Which benchmark size is used is defined by the `BENCHMARK` variable in the Makefile.

The Makefile allows the specification of the implementation for each language via the `JULIA` and `PYTHON` variables. It defaults
to assuming that they are on the path with names `julia` and `python3`, respectively, but this can be configured by changing their
definitions in the makefile.

By default, performance results will only be written to stdout. To specify a target folder, set the `OUTPUT` variable in the makefile.