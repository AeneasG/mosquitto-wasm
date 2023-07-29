make clean
rm src/mosquitto.aot ~/wasm-micro-runtime/product-mini/platforms/linux-sgx/enclave-sample/mosquitto.aot
make TARGET_WASM=yes TARGET_INTEL_SGX=yes
~/wasm-micro-runtime/wamr-compiler/build/wamrc -sgx --bounds-checks=0 -o src/mosquitto.aot src/mosquitto
mv src/mosquitto.aot ~/wasm-micro-runtime/product-mini/platforms/linux-sgx/enclave-sample/mosquitto.aot