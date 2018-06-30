./harness.sh "binary_trees" ./binary_tree.run ${BTREE_DEPTH:-21}
./harness.sh "fannkuch" ./fannkuch.run ${FANNKUCH_SIZE:-12}
./harness.sh "fasta" ./fasta.run ${FASTA_SIZE:-25000000}
./harness.sh "knucleotide" ./knucleotide.run < ${KNUC_FILE:-$1/fasta25m.inp}
./harness.sh "mandelbrot" ./mandelbrot.run ${MANDELBROT_SIZE:-16000}
./harness.sh "nbody" ./nbody.run ${NBODY_SIZE:-50000000}
./harness.sh "pidigits" ./pidigits.run ${PIDIGITS_NUM:-10000}
./harness.sh "regex" ./regex_redux.run < ${REGEX_FILE:-$1/fasta5m.inp}
./harness.sh "revcomp" ./revcomp.run < ${REVCOMP_FILE:-$1/fasta25m.inp}
./harness.sh "spectralnorm" ./spectralnorm.run ${SPECTRALNORM_SIZE:-5500}
