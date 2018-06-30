all: binary_tree.run fasta.run regex_redux.run revcomp.run fannkuch.run knucleotide.run \
	pidigits.run nbody.run spectralnorm.run mandelbrot.run meteor_contest.run

clean:
	rm -f *.run

binary_tree.run: binary_tree.c
	gcc -pipe -Wall -O3 -fomit-frame-pointer -march=native -D_FILE_OFFSET_BITS=64 \
		-I/usr/include/apr-1.0 $< -o $@ -lapr-1 -lgomp -lm
fasta.run: fasta.c
	gcc -pipe -Wall -O3 -fomit-frame-pointer -march=native -std=c99 -mfpmath=sse -msse3 \
		-fopenmp $< -o $@
regex_redux.run: regex-redux.c
	gcc -pipe -Wall -O3 -fomit-frame-pointer -march=native \
		-fopenmp $< -o $@ -lpcre
revcomp.run: revcomp.c
	gcc -pipe -Wall -O3 -fomit-frame-pointer -march=native -fopenmp $< -o $@

fannkuch.run: fannkuch.c
	gcc -pipe -Wall -O3 -fomit-frame-pointer -march=native -std=c99 -fopenmp $< -o $@

knucleotide.run: knucleotide.c
	gcc -pipe -Wall -O3 -fomit-frame-pointer -march=native -std=c99 -fopenmp -IInclude $< -o $@

pidigits.run: pidigits.c
	gcc -pipe -Wall -O3 -fomit-frame-pointer -march=native $< -o $@ -lgmp

nbody.run: nbody.c
	gcc -pipe -Wall -O3 -fomit-frame-pointer -march=native -mfpmath=sse -msse3 $< -o $@ -lm

spectralnorm.run: spectralnorm.c
	gcc -pipe -Wall -O3 -fomit-frame-pointer -march=native -mfpmath=sse -msse2 -fopenmp $< -o $@ -lm

mandelbrot.run: mandelbrot.c
	gcc -pipe -Wall -O3 -fomit-frame-pointer -march=native -mno-fma -fno-finite-math-only -mfpmath=sse -msse2 $< -o $@

meteor_contest.run: meteor_contest.c
	gcc -pipe -Wall -O3 -fomit-frame-pointer -march=native $< -o $@


