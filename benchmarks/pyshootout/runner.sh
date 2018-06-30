./harness.sh "binary_trees" ./binarytrees.py ${BTREE_DEPTH:-21} $2
./harness.sh "fannkuch" ./fannkuchredux.py ${FANNKUCH_SIZE:-12} $2
./harness.sh "fasta" ./fasta.py ${FASTA_SIZE:-25000000} $2
(./harness.sh "knucleotide" ./knucleotide.py "" $2) < ${KNUC_FILE:-$1/fasta25m.inp}
./harness.sh "mandelbrot" ./mandelbrot.py ${MANDELBROT_SIZE:-16000} $2
./harness.sh "nbody" ./nbody.py ${NBODY_SIZE:-50000000} $2

if [ $2 = "python3" ]
then
   ./harness.sh "pidigits" ./pidigits_cpython.py ${PIDIGITS_NUM:-10000} $2   
else
    ./harness.sh "pidigits" ./pidigits_pypy.py ${PIDIGITS_NUM:-10000} $2
fi

(./harness.sh "regex" ./regexredux.py "" $2) < ${REGEX_FILE:-$1/fasta5m.inp}
./harness.sh "revcomp" ./revcomp.py "" $2 < ${REVCOMP_FILE:-$1/fasta25m.inp}
./harness.sh "spectralnorm" ./spectralnorm.py ${SPECTRALNORM_SIZE:-5500} $2


