echo -n $1 " "
export OMP_NUM_THREADS=1
export OMP_THREAD_LIMIT=1
/usr/bin/time -f "%E" $2 $3 > /dev/null
