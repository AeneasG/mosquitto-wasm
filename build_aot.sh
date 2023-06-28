make clean
rm src/mosquitto.aot ~/wasm-micro-runtime/product-mini/platforms/linux-sgx/enclave-sample/mosquitto.aot
make RUNTARGET=WASM
~/wasm-micro-runtime/wamr-compiler/build/wamrc -sgx -o src/mosquitto.aot src/mosquitto.wasm
mv src/mosquitto.aot ~/wasm-micro-runtime/product-mini/platforms/linux-sgx/enclave-sample/mosquitto.aot