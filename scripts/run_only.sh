#!/bin/bash

# setup environment
my_pid=$BASHPID
rdycheck__exec=$1
postuart__exec=$2
postdebug_exec=$3
#echo "exec when uart  ready: $postuart__exec"
#echo "exec when debug ready: $postdebug_exec"
tempfifo="./temp/interactive.in"
tempuartlog="./temp/uart.log"
temprunlog="./temp/run.log"
echo "---------------------------"
echo "uart log > $tempuartlog"
echo "run log  > $temprunlog"
echo "---------------------------"

# create temp folder if it doesn't exist yet
mkdir -p ./temp
rm ./temp/*

# setup finalization
finalizer() {
    printf "\nFinalizing..\n"
    rm $tempfifo
}
catcher() {
    trap '' INT TERM
    printf "\nSIGINT caught\n"
    finalizer
    kill -TERM 0
    wait
    echo "Done..\n"
    exit 2
}
trap 'catcher' INT TERM

# setup fifo
if [ ! -p $tempfifo ]; then
    mkfifo $tempfifo
else
    echo "another interactive session is still running" >&2
    exit 1
fi

# check if the connection is ready
if ! $rdycheck__exec ; then
    kill -SIGINT ${my_pid}
fi

# start interactive session
# uart can be connected now
echo
echo "uart ready!"
# run postuart
(tail -f --pid=$my_pid $tempfifo | $postuart__exec > $tempuartlog) &
interactive_pid=$!

sleep 1

# jtag can be connected now
echo
echo "jtag ready!"
# run postdebug
$postdebug_exec > $temprunlog

sleep 1

# cleanup
finalizer

