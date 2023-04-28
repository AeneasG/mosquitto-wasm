#!/bin/bash

# Very basic client testing.


set -e

export BASE_PATH=../../
export LD_LIBRARY_PATH=${BASE_PATH}/lib
export PORT=1888
export SUB_TIMEOUT=1

# Start broker
../../iwasm --allow-resolve=* --addr-pool=0.0.0.0/32,0000:0000:0000:0000:0000:0000:0000:0000/64 --dir=. ../../src/mosquitto.wasm -p ${PORT} 2>/dev/null &
export MOSQ_PID=$!
sleep 0.5

# Kill broker on exit
trap "kill $MOSQ_PID" EXIT


# Simple subscribe test - single message from $SYS
../../iwasm --allow-resolve=* --addr-pool=0.0.0.0/32,0000:0000:0000:0000:0000:0000:0000:0000/64 ${BASE_PATH}/client/mosquitto_sub.wasm -p ${PORT} -W ${SUB_TIMEOUT} -C 1 -t '$SYS/broker/uptime' >/dev/null
echo "Simple subscribe ok"

# Simple publish/subscribe test - single message from mosquitto_pub
../../iwasm --allow-resolve=* --addr-pool=0.0.0.0/32,0000:0000:0000:0000:0000:0000:0000:0000/64 ${BASE_PATH}/client/mosquitto_sub.wasm -p ${PORT} -W ${SUB_TIMEOUT} -C 1 -t 'single/test' >/dev/null &
export SUB_PID=$!
../../iwasm --allow-resolve=* --addr-pool=0.0.0.0/32,0000:0000:0000:0000:0000:0000:0000:0000/64 ${BASE_PATH}/client/mosquitto_pub.wasm -p ${PORT} -t 'single/test' -m 'single-test'
kill ${SUB_PID} 2>/dev/null || true
echo "Simple publish/subscribe ok"

# Publish a file and subscribe, do we get at least that many lines?
export TEST_LINES=$(wc -l test_wasi.sh | cut -d' ' -f1)
../../iwasm --allow-resolve=* --addr-pool=0.0.0.0/32,0000:0000:0000:0000:0000:0000:0000:0000/64 --dir=. ${BASE_PATH}/client/mosquitto_sub.wasm -p ${PORT} -W ${SUB_TIMEOUT} -C ${TEST_LINES} -t 'file-publish' >/dev/null &
export SUB_PID=$!
../../iwasm --allow-resolve=* --addr-pool=0.0.0.0/32,0000:0000:0000:0000:0000:0000:0000:0000/64 --dir=. ${BASE_PATH}/client/mosquitto_pub.wasm -p ${PORT} -t 'file-publish' -f ./test_wasi.sh
kill ${SUB_PID} 2>/dev/null || true
echo "File publish ok"

# Publish a file from stdin and subscribe, do we get at least that many lines?
# export TEST_LINES=$(wc -l test_wasi.sh | cut -d' ' -f1)
# ${BASE_PATH}/iwasm --allow-resolve=* --addr-pool=0.0.0.0/32,0000:0000:0000:0000:0000:0000:0000:0000/64 --dir=. ${BASE_PATH}/client/mosquitto_sub.wasm -p ${PORT} -W ${SUB_TIMEOUT} -C ${TEST_LINES} -t 'file-publish' >/dev/null &
# export SUB_PID=$!
# ${BASE_PATH}/iwasm --allow-resolve=* --addr-pool=0.0.0.0/32,0000:0000:0000:0000:0000:0000:0000:0000/64 --dir=. ${BASE_PATH}/client/mosquitto_pub.wasm -p ${PORT} -t 'file-publish' -l < ./test_wasi.sh
# kill ${SUB_PID} 2>/dev/null || true
echo "stdin publish not supported in WASM, skipped!"
