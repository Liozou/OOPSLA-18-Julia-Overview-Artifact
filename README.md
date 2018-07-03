# Julia: Dynamism and Performance Reconciled by Design (ARTIFACT)

This artifact contains the following:

- A release of Julia v0.6.2, instrumented to allow to dynamically record function calls and to do both static and dynamic analyses on packages. This is in the `julia/` directory.
- A release of Julia v0.6.2 and LLVM suitable for recompilation at different optimization levels. This is in the `julia-benchmark/` directory.

This will allow to replicate the following results:
- Fig 7, pg. 5: Slowdown relative to C.
- Fig. 14, pg.15.  Targets per call site.
- Fig. 12, pg.16: Numbers of method and types
- Fig. 13, pg.16: Percentage of type annotations
- Fig. 16 pg. 17: Dispatch ratios
- Fig. 17 and 18 pg. 18: Num arguments dispatched on, %overload
- Fig. 20 and 21 pg. 20: Num specialization per met, Applicable methods
- Source data for fig. 22 pg. 20: Optimization and performance.

The following results are not supported in the artifact:
- Fig. 6, pg. 4: Person-year. Requires analysis of commit logs. This is not a key result; code omitted.
- Fig 9, pg. 11: Source code lines. Obtained by cloc. This was not automated.
- Fig. 15 pg. 17: Muschevici et al. metrics. Data comes from Muschevici et al. [2008]
- Fig. 19 pg. 19: Function overloads by category. Obtained by manually classifying 128 function names into the different categories.

## Getting Started

Our artifact is included in a VirtualBox VM. The password for root and the user artifact is " " (one space). To start, open the artifact directory on the desktop of the virtual machine. Paths referred to in this document will be relative to the `artifact/` directory.

### Main figures

We have bundled the instructions for generating the data for our work in a runnable script. From a terminal in `~/Desktop/artifact/`, type:

```sh
./make_plots.sh
```

This will generate the data and plots for figure 7,12, 13, 14, 16, 17, 20 and 21. This is expected to take between 5 to 10 minutes, depending on hardware virtualization support and performance. To check that this worked, look in the `plots/` subdirectory, which should have several PDFs containing versions of the figures in the paper. Source data will be placed into the `data/` subdirectory. For figure 22, multiple versions of Julia compiled at different optimization levels are required.

### Reproducing Figure 22
Reproducing Fig 22 requires building Julia with different optimizations disabled. This is time consuming and invasive, so we have prepared a separate directory with all of the code you will need for this. This is bundled as part of the julia-benchmark folder, which is also used for executing the benchmarks. To compile and run the benchmarks with Julia compiled using different optimization flags, do the following:

```sh
cd julia-benchmark
make opt-zero
make run-opt-zero
make no-inf
make run-no-inf
make no-devirt
make run-no-devirt
```
The above will cause Julia to be built and to run of the benchmarks. Each one will take between 15 and 20 minutes depending on performance and hardware virtualization support. Benchmark results will be placed in the `julia-benchmark/benchmark_results` directory. To revert the state to the baseline, run:

```sh
make julia-O2
```
from inside the julia-benchmark folder.

For additional background, running Julia with no LLVM optimization is simply done by `julia -O0`, disabling type inference required us to replace file  `jl_type_infer` in `src/gf.c` with an identical file with line 236 having `return NULL;` and recompiling, and disabling method devirtualization was done by commenting out line 2905 of `base/inference.jl`. Recompilation of Julia should be around 15 minutes long.


## Additional information

The instrumented Julia REPL is launched by typing `julia/julia` from the base directory.

Installing a package can be done by typing `Pkg.add("PackageName")`. Packages `DataStreams` and `Lazy` are examples already installed in the VM.

Now we give more details about some of our infrastructure for the interested reader.

### Recording function calls
To record function calls between two points, add the following lines to the code. To start recording `ccall(:jl_start_instrumentation, Void, ())`  and to end it `ccall(:jl_end_instrumentation, Void, ())`.  Recording can be paused by `ccall(:jl_stop_instrumentation, Void, ())` and restarted with `ccall(:jl_start_instrumentation, Void, ())`.  The record is written to standard error which should be piped into a log file.

The log may be polluted by Julia error messages. These should only appear before and after the actual log, not in the middle of it, so they can easily be removed.

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

### Recording test suites

We modified the Julia `Pkg.test` function to record all calls occuring during package test suites. To do so, run
```julia
Pkg.test("P")
```
This generates 4 files in the `logs` folder. `P.log` is the raw log. `dyns/P.dyn` is the parsed version of the log. `static/P.static` contains all the methods accessible during the tests, grouped by the function they refine. This information is essentially static, but it is completed by the number of calls and the number of specializations that happened during the tests, which are dynamic values. `unk/P.unk` contains the names of the functions in the dynamic log but not in the static data. They are not true methods: rather, they are builtin functions that cannot be overloaded. As such, they are out of the scope of our study (less than 10 functions in total).

The last three files are Julia file, which can be imported in Julia with
```julia
obj = load_back(“file_path”)
```
where `load_back` is defined in `analytics/measure_dispatch`. `DataStreams` and `Lazy` are already tested in the VM. Note that testing may take significantly more time than without the instrumentation. The names of the packages used in the article can be found at `analytics/studied_packages.txt`.

### Analyses

The data for `DataStreams` and `Lazy` has already been collected in the VM.

#### Data collection

Once `.log`, `.dyn` and `.static` files are in the `julia/logs/` folder, the metrics can be collected by uncommenting the last line of `julia/analytics/collect_data.jl` and executing the file. The result is stored in the `julia/logs/data/` folder. Leaving the last line commented allows to load the functions from the file without launching the data collecting process.

Two directories are also created, `julia/logs/static_soft/` and `julia/logs/static_strict/` which contain `.static` files analogous to those in `julia/logs/static/`. They correspond to the functions that passed either the _strict_ or the _soft_ elimination, as defined in the paper.

The `julia/logs/data/` folder itself is subdivided into five different subfolders:
- `function`: dynamic data collected on functions that were not generated by the compiler nor anonymous
- `nonsinglefunction`: refines the precedent class by only keeping functions with at least two methods.
- `static`: static data collected on all functions not generated by the compiler nor anonymous.
- `static_strict`: refines the `static` data with strict elimination.
- `static_soft`: refines the `static` data with soft elimination.

Each of the produced files has a name of the form "source.txt" where `source` is the name of the function from `julia/analytics/collect_data.jl` that generated the data.
The files themselves are composed of lines starting with `PackageName:` followed by the relevant data for the given package. Refer to the documentation of each generating function for more details about the data.

Many relevant metrics can be obtained by merging the data from different packages (using either strict or soft elimination). The functions from `analytics/combine_data.jl` retrieve data from the `logs/data/` folder and process the combined results for various metrics, such as the number of methods per function for instance.

To obtain the data for the figures of the paper, execute `analytics/generate_csv.jl` (after having run `set_logs_dir("$JULIA_HOME/../../logs/")`, the comment at the last line of `analytics/collect_data.jl`). This will fill the `logs/csv/` folder with `.csv`, `.data` and `.txt` files.
- `.csv` and `.data` represent comma-separated data files, the former being specific to the case where there are only two values per line.
- `.txt` are used for documentation. Each `.txt` file explains the contents of the corresponding either `.csv` or `.data` file with the same name.


### Micro-benchmarks

Benchmark source code for Julia, untyped Julia, JavaScript, C, and Python is included as part of the artifact, along with our execution harness. The VM image contains their source, but is not configured to execute them. The following prerequisites are required to run the benchmarks:

* Python 3.5.3
* Node.js v8.11.1
* Julia 0.6.2
* gcc 6.3.0
* R 3.4.4

Node dependencies are in the package-lock.json file inside the jsshootout folder.

Benchmarks reside within the `analysis/benchmarks` folder, which contains both the implementations and the runner infrastructure. Execution is via the makefile at the top level, which both compiles and runs the benchmarks on demand. The folders serve the following purposes:

* `benchmark_defns` defining benchmark sizes;
* `cshootout` for C benchmarks
* `jlnoty-shootout` for untyped versions of Julia benchmarks that had types originally
* `jlshootout` for Julia benchmarks with all original type annotations
* `jsshooutout` for Javascript benchmarks
* `pyshootout` for Python benchmarks
* `results` for the data in the figure as well as the scripts to generate the figure from the paper.

Each language's benchmark suite has its own target, and the default target is the Julia benchmark. Available targets are:

* `run_jl_benchmarks` (default) for running the typed Julia benchmarks;
* `run_jl_benchmakrs_noty` for untyped versions of typed Julia benchmarks;
* `run_py_benchmarks` for Python benchmarks;
* `run_js_benchmarks` for JavaScript benchmarks;
* `run_c_benchmarks` for C benchmarks;
* `run_pypy_benchmarks` for (supplemental) PyPy benchmarks (requires PyPy).

The benchmarks, from the Programming Language Benchmark Game, are parameterized over problem sizes defined in `benchmark_defns`. Numbers reported in the paper come from `full_size.sh`, but `small_size.sh` can be used while testing the environment for quick
execution. Which benchmark size is used is defined by the `BENCHMARK` variable in the Makefile.

The Makefile allows the specification of the implementation for each language via the `JULIA` and `PYTHON` variables. It defaults to assuming that they are on the path with names `julia` and `python3`, respectively, but this can be configured by changing their definitions in the Makefile. By default, performance results will only be written to stdout. To specify a target folder, set the `OUTPUT` variable in the Makefile.
