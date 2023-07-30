WAMR_PATH=${1:-/opt/wasm-micro-runtime}

make clean
make TARGET_WASM=yes
$WAMR_PATH/wamr-compiler/build/wamrc -o src/mosquitto.aot src/mosquitto
echo "Now run ./iwasm --allow-resolve=* --addr-pool=0.0.0.0/32,0000:0000:0000:0000:0000:0000:0000:0000/64 --heap-size=4294967296 --dir=. src/mosquitto.aot -c mosquitto.conf"