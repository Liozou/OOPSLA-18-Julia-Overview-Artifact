echo -n $1 " "
/usr/bin/time -f "%E" $4 $2 $3 > /dev/null
