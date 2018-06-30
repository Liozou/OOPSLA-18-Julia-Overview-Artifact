./harness.sh "binary_trees" binary-trees.js ${BTREE_DEPTH:-21}
./harness.sh "fannkuch" fannkuch.js ${FANNKUCH_SIZE:-12}
./harness.sh "fasta" fasta.js ${FASTA_SIZE:-25000000}
./harness.sh "knucleotide" knucleotide.js < ${KNUC_FILE:-$1/fasta25m.inp}
./harness.sh "mandelbrot" mandelbrot.js ${MANDELBROT_SIZE:-16000}
./harness.sh "nbody" nbody.js ${NBODY_SIZE:-50000000}
./harness.sh "pidigits" pidigits.js ${PIDIGITS_NUM:-10000}
./harness.sh "regex" regex-redux.js < ${REGEX_FILE:-$1/fasta5m.inp}
./harness.sh "revcomp" revcomp.js < ${REVCOMP_FILE:-$1/fasta25m.inp}
./harness.sh "spectralnorm" spectralnorm.js ${SPECTRALNORM_SIZE:-5500}
