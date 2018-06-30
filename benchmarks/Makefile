GENERATED_INPUT_DIR:=input
C_SHOOTOUT:=cshootout
PY_SHOOTOUT:=pyshootout
JL_SHOOTOUT:=shootout
JL_NOTY_SHOOTOUT:=jlnoty-shootout
JS_SHOOTOUT:=jsshootout
FASTA_BIN:=$(C_SHOOTOUT)/fasta.run
BENCHMARK_DEFNS:=benchmark_defns
JULIA_CONFIG:=o2

# CHANGEME
JULIA:=julia
PYPY:=pypy #relative to PY_SHOOTOUT dir
PYTHON:=python3

BENCHMARK:=full_size.sh
POSTFIX:=""
OUTPUT:=

run_jl_benchmarks : inputs
	source $(BENCHMARK_DEFNS)/$(BENCHMARK) $(PWD)/$(GENERATED_INPUT_DIR); \
	$(JULIA) $(JL_SHOOTOUT)/perf.jl 2>&1 | tee $(OUTPUT)

run_jl_benchmarks_noty : inputs
	source $(BENCHMARK_DEFNS)/$(BENCHMARK) $(PWD)/$(GENERATED_INPUT_DIR); \
	$(JULIA) $(JL_NOTY_SHOOTOUT)/perf.jl 2>&1 | tee $(OUTPUT)

run_py_benchmarks : inputs
	source $(BENCHMARK_DEFNS)/$(BENCHMARK) $(PWD)/$(GENERATED_INPUT_DIR); \
	cd $(PY_SHOOTOUT); ./runner.sh $(PWD)/$(GENERATED_INPUT_DIR) $(PYTHON) 2>&1 | tee $(OUTPUT)

run_pypy_benchmarks : inputs
	source $(BENCHMARK_DEFNS)/$(BENCHMARK) $(PWD)/$(GENERATED_INPUT_DIR); \
	cd $(PY_SHOOTOUT); ./runner.sh $(PWD)/$(GENERATED_INPUT_DIR) $(PYPY) 2>&1 | tee $(OUTPUT)

run_c_benchmarks : inputs cshootout
	source $(BENCHMARK_DEFNS)/$(BENCHMARK) $(PWD)/$(GENERATED_INPUT_DIR); \
	cd $(C_SHOOTOUT); ./runner.sh $(PWD)/$(GENERATED_INPUT_DIR) 2>&1 | tee $(OUTPUT)

run_js_benchmarks : inputs
	source $(BENCHMARK_DEFNS)/$(BENCHMARK) $(PWD)/$(GENERATED_INPUT_DIR); \
	cd $(JS_SHOOTOUT); ./runner.sh $(PWD)/$(GENERATED_INPUT_DIR) 2>&1 | tee $(OUTPUT)

inputs : cshootout
	mkdir -p $(GENERATED_INPUT_DIR)
	$(FASTA_BIN) 100000 > $(GENERATED_INPUT_DIR)/fasta100k.inp
	$(FASTA_BIN) 5000000 > $(GENERATED_INPUT_DIR)/fasta5m.inp
	$(FASTA_BIN) 25000000 > $(GENERATED_INPUT_DIR)/fasta25m.inp

cshootout :
	cd "cshootout"; $(MAKE)

.PHONY : cshootout inputs
