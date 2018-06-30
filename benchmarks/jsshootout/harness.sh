NODE=../../other-vms/node-v8.11.1-linux-x64/bin/node
echo -n $1 " "
/usr/bin/time -f "%E" $NODE $2 $3 > /dev/null
