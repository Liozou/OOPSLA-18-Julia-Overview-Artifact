include("combine_data.jl")

#=
This file offers a utility to automatically store the values collected to plot
the figures of the article intp the `logs/csv/` folder.

If you have tested a new package and want to update the values:
1) Run `set_logs_dir("$JULIA_HOME/../../logs/")` from a Julia REPL.
2) Execute this file again.
=#

info("Generating data for the figures")

CSV_DIR = LOGS_DIR*"csv/"
mkpath(CSV_DIR)


open(CSV_DIR*"targets_per_callsite_per_package.data", "w") do io
    specializations_per_method(LOGS_DIR, io)
end
open(CSV_DIR*"targets_per_callsite_per_package.txt", "w") do io
    println(io, "Number of targets per call site for each package.

x: Name of the package
y1: Number of call sites that only have 1 target
y2: Number of call sites that have exactly 2 targets
y3: Number of call sites that have at 3 or more targets

Collected on the dynamic data, for the package functions.

Shows that optimizing inlining could be very useful. It does not prove that the call sites will only ever have this number of targets though.
")
end


open(CSV_DIR*"muschevici_metrics_with_arity_strict.data", "w") do io
    muschevici_metrics(LOGS_DIR, true, io)
end
open(CSV_DIR*"muschevici_metrics_with_arity_strict.txt", "w") do io
    println(io, "Collect some of the metrics that are used in the article by Muschevici et al. per package.

Package: Name of the package.
DR: Dispatch ratio i.e. average number of methods per function.
CR: Choice ratio i.e. mean square number of methods per function.
DoD: Degree of dispatch i.e. average number of arguments dispatched on per function.
RD: Rightmost dispatch i.e. average index of the last argument dispatched on.
Discrepancy: average number of functions for which RD!=DoD (not a metric in the original article)

Data collected on the static data for functions that had all their method definitions in the studied package.
Functions are considered by name arity.
")
end
open(CSV_DIR*"muschevici_metrics_with_arity_soft.data", "w") do io
    muschevici_metrics(LOGS_DIR, false, io)
end
open(CSV_DIR*"muschevici_metrics_with_arity_soft.txt", "w") do io
    println(io, "Collect some of the metrics that are used in the article by Muschevici et al. per package.

Package: Name of the package.
DR: Dispatch ratio i.e. average number of methods per function.
CR: Choice ratio i.e. mean square number of methods per function.
DoD: Degree of dispatch i.e. average number of arguments dispatched on per function.
RD: Rightmost dispatch i.e. average index of the last argument dispatched on.
Discrepancy: average number of functions for which RD!=DoD (not a metric in the original article)

Data collected on the static data for functions that had at least one method definition in the studied package.
Functions are considered by name arity.
")
end


open(CSV_DIR*"arguments_dispatch.csv", "w") do io
    arguments_dispatch(LOGS_DIR, io)
end
open(CSV_DIR*"arguments_dispatch.txt", "w") do io
    println(io, "Number of arguments dispatched on per function/arity.

x: Number of arguments dispatch is done on
y: Number of corresponding function/arity

Computed by taking all the different methods for a given function/arity and counting the number of arguments that have a different type in the signature of at least two methods.
Collected on the static data. Each studied function had all its methods defined in the tested package. Each studied function had at least one argument.

Note: Looks good with y log scale!
Note: The winner function for the number of arguments dispatched on is Base.Linalg.ARPACK.neupd that has 4 methods taking 25 or 26 arguments, and requiring a dispatch on 7 of them.
")
end


open(CSV_DIR*"specializations_per_method.csv", "w") do io
    specializations_per_method(LOGS_DIR, io)
end
open(CSV_DIR*"specializations_per_method.txt", "w") do io
    println(io, "For all user-defined method, the number of specializations done.

x: Number of specializations
y: Number of corresponding methods

Collected on the strict static data after having run the tests (the number of specializations is a dynamic feature).

Shows that approximately half of all the methods are only specialized once, which hints at the fact that programmers write such methods with the wanted specialization in mind. The heavy tail is indicative of the polymorphism Julia offers. Overall, all kinds of methods from tailor-made to generic are used.
The methods with 0 specialization are those that are not called, they are not taken into account since they are only indicative of the coverage.
")
end

open(CSV_DIR*"applicable_methods_per_call_signature.csv", "w") do io
    specializations_per_method(LOGS_DIR, io)
end
open(CSV_DIR*"applicable_methods_per_call_signature.txt", "w") do io
    println(io, "For each call signature the number of applicable methods.

x: Number of applicable methods
y: Number of call signatures

Collected on the functions that had *at least two method definitions*.

Show that the specificity rule is not that used. Hints that programmers mostly write method definitions with concrete type annotations.
")
end
