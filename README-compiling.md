The following packages can be used to add features to mosquitto. All of them
are optional.

* openssl
* c-ares (for DNS-SRV support, disabled by default)
* tcp-wrappers (optional, package name libwrap0-dev)
* libwebsockets (optional, disabled by default, version 2.4 and above)
* cJSON (optional but recommended, for dynamic-security plugin support, and
  JSON output from mosquitto_sub/mosquitto_rr)
* libsystemd-dev (optional, if building with systemd support on Linux)
* On Windows, a pthreads library is required if threading support is to be
  included.
* xsltproc (only if building from git)
* docbook-xsl (only if building from git)

To compile, run "make", but also see the file config.mk for more details on the
various options that can be compiled in.

Where possible use the Makefiles to compile. This is particularly relevant for
the client libraries as symbol information will be included.  Use cmake to
compile on Windows or Mac.

If you have any questions, problems or suggestions (particularly related to
installing on a more unusual device) then please get in touch using the details
in README.md.

# Compile to WASM using WASI-SDK and run with WAMR
For research purposes, mosquitto has been ported to WASM using WASI-SDK and WAMR. This guide aims to explain the necessary steps to come up with a basic and running version of Mosquitto. Note, that **not** all features are supported that native mosquitto supports.

## Prerequisites
Install WASI-SDK as well as WAMR-SDK as follows:
### WASI-SDK
Get a release of WASI-SDK from [here](https://github.com/WebAssembly/wasi-sdk/releases). For this guide, `wasi-sdk-20` has been used. Extract the archive to `/opt/wasi-sdk`.

### WAMR
Clone the repo of WAMR from [here](https://github.com/bytecodealliance/wasm-micro-runtime). At the time of writing, the commit `aaf671d` has been used.

Optimally, clone WAMR into `/opt/wasm-micro-runtime` in order to avoid extra configuration later.

#### Build WAMR
Build your own WAMR runtime according to the guides provided in the repo or [here](https://wamr.gitbook.io/document/). For this guide, the runtime has been built for `Linux`.

## Compile Mosquitto
Build mosquitto as follows:
```bash
#! Root of repo
# ensure everything is clean before starting
make clean
# build with make
# you can omit WAMR_PATH if it equals to /opt/wasm-micro-runtime
# you can omit WASI_SDK_PATH if it equals to /opt/wasi-sdk
make RUNTARGET=WASM WAMR_PATH=/path/to/WAMR/root WASI_SDK_PATH=/path/to/WASI-SDK/root 
```
You can add any other option to build mosquitto as described in the standard mosquitto documentation. However, note, that not all options are supported in WASI nor have been tested.

Currently, known options that are not supported or not tested are:
* `WITH_WRAP`
* `WITH_BRIDGE`
* `WITH_DB_UPGRADE`
* `WITH_SYSTEMD`
* `WITH_SRV`
* `WITH_WEBSOCKETS`
* `WITH_EC`
* `WITH_ADNS`
* `WITH_EPOLL` (no support in WASI)
* `WITH_UNIX_SOCKETS` (no support in WASI)
* `WITH_JEMALLOC` (must provide JEMALLOC WASI library)

Additionally, the following features are not supported / are not working
* Signal handling
* Plugin loading
* Build the shared library (shared library building is not yet supported by [WASI-SDK](https://github.com/WebAssembly/wasi-sdk#notable-limitations))

Experimental options
* `WITH_THREADING`: App compiles but might behave unexpected, e.g. tests are not able to compile and run

Known options, that are supported
* `WITH_TLS` (WITH WolfSSL only, see comment below)
* `WITH_TLS_PSK`
* `WITH_PERSISTENCE`
* `WITH_MEMORY_TRACKING`
* `WITH_SYS_TREE`
* `WITH_SOCKS` (probably only impact on client)
* `WITH_CJSON` (only relevant to the client)
* `WITH_CONTROL`

### TLS
WolfSSL has been used to provide TLS for mosquitto in the WASM version. WolfSSL works in general also for the Linux version of mosquitto. To enable WolfSSL (instead of the default OpenSSL), specify

``-DWITH_WOLFSSL=1``

#### Build WolfSSL
You will probably have to build first WolfSSL. To do so, perform the following steps:
1. Clone [WolfSSL](https://github.com/X-Margin-Inc/wolfssl)
2. Build and install the linux version to have the header files installed
```bash
./autogen
# ocsp is an alternative way of validating certificates
# enable-all makes sure the openssl compatibility layer is built as well
./configure --enable-ocsp --enable-nginx --enable-opensslall --enable-stunnel

make
sudo make install
# update the linker cache
sudo ldconfig 
```

3. Prepare build of WolfSSL for WASM
Go to `wolfssl/wolfio.h` and add the following lines at the top of the file

```c
#ifdef   __wasi__
#include   <arpa/inet.h>;
#include   <netinet/in.h>;
#endif
```

Then, in `$WOLFSSLROOT/IDE/Wasm/wasm_static.mk` add to the `Wolfssl_C_Extra_Flags` the following flags
``-DHAVE_OCSP -DHAVE_CERTIFICATE_STATUS_REQUEST -DOPENSSL_EXTRA -DOPENSSL_ALL -DHAVE_EX_DATA -DSESSION_CERTS -DWOLFSSL_SYS_CA_CERTS -DOPENSSL_COMPATIBLE_DEFAULTS``

4. Build WolfSSL for WASM
````bash
cd $WOLFSSLROOT/IDE/Wasm
make -f wasm_static.mk clean
make -f wasm_static.mk all
sudo cp libwolfssl.a /usr/local/lib/libwolfssl.a
````

Now you should be ready to build mosquitto with WolfSSL by running
````bash
# add your config to config.mk, then
make clean && make RUNTARGET=WASM
````

### Build for Linux SGX
Mosquitto is able to run in an [Intel SGX](https://www.intel.com/content/www/us/en/developer/tools/software-guard-extensions/overview.html) enclave with a few tradeoffs. Mosquitto will be running completely in the trusted part backed by [WAMR](https://github.com/bytecodealliance/wasm-micro-runtime). WAMR is able to load a WASM module into the trusted part and execute it completely isolated from the rest of the operating system. If you like to use TLS, you have to use WolfSSL (as described before, no more changes necessary). If you don't like to use TLS, then some adaptations in the code will be necessary as the broker currently expects certificates at compile time as well as at runtime.

The current tradeoffs are as follows:
* Certificates must be embedded at compile-time and are loaded from buffers instead of the filesystem
* Configuration must be embedded at compile-time and is loaded from a buffer

Further, there are some features not working as expected compared to the native version, i.e.
* Domain Name Resolution: The broker will listen on every IP address given a port
* Persistence: Currently persistence is not yet working
* Differenct certificates per listener are not implemented
* ACL as well as CRL are not implemented
* all features not working in WASM won't work here either

#### Compile
To get started, create in the root of this project a file called `mosquitto.conf` and put your configuration of the broker in it. You can omit the references to `cafile`, `certfile` as well as `keyfile`. Also note the section above about non-working features.

Next, create a folder in the root of this project called `certs` and place the following files in it with the correct name:
* `server.key`: the broker's private key
* `server.crt`: the server's certificate for the corresponding private key
* `ca.crt`: the certificate chain of all trusted certificates

If you have done these steps, you can run in the root of this project the following build command:
```bash
make RUNTARGET=WASM TARGET_INTEL_SGX=yes
```

Build the `wamrc` compiler as described [here](https://wamr.gitbook.io/document/basics/getting-started/build_wasm_app#compile-wasm-to-aot-module) and compile the wasm module outputted from the previous step using the following command
```bash
./wamrc -sgx -o src/mosquitto.aot src/mosquitto.wasm
```


## Run with WAMR
Use your previously built WAMR runtime (in the following a file called `iwasm`) to run mosquitto as follows:
```bash
./iwasm --allow-resolve=<domains allowed to resolve> --addr-pool=<addr-pool to bind> src/mosquitto.wasm
```
To run it locally, you can for example run
```bash
# allow to resolve any domain and allow to bind IPv4 and IPv6 loopback addresses
./iwasm --allow-resolve=* --addr-pool=0.0.0.0/32,0000:0000:0000:0000:0000:0000:0000:0000/64 src/mosquitto.wasm
```
To run with config, you should first tell the wasm runtime that mosquitto has the right to access the config file and then tell mosquitto the location of the config file
```bash
./iwasm --allow-resolve=* --addr-pool=0.0.0.0/32,0000:0000:0000:0000:0000:0000:0000:0000/64 --dir=. src/mosquitto.wasm -c mosquitto.conf
```
Please note: As WASI `getaddrinfo` does not support to not specify the IP protocol version, a warning will be printed by mosquitto when you specify a listener in the config, and it will try to determine the IP protocol version by analyzing the address which usually succeeds.

## Run the client
The client can be run as well using the following commands:
### Subscribe
```bash
./iwasm --allow-resolve=* --addr-pool=0.0.0.0/32,0000:0000:0000:0000:0000:0000:0000:0000/64 client/mosquitto_sub.wasm -t 'test'
```
### Publish
```bash
./iwasm --allow-resolve=* --addr-pool=0.0.0.0/32,0000:0000:0000:0000:0000:0000:0000:0000/64 client/mosquitto_pub.wasm -t 'test' -m "Hello World"
```

## Run with SGX
To run mosquitto in an Intel SGX enclave, you need to build first the WAMR runtime for Intel SGX. To do so, build [WAMR](https://github.com/bytecodealliance/wasm-micro-runtime) in `product-mini/platforms/linux-sgx` as well as `product-mini/platforms/linux-sgx/enclave-sample` as described in the corresponding `README`. Use the `iwasm` from the `enclave-sample` build step to run the `mosquitto.aot` from your last build step. The commands to start the broker are the same except that you don't need to pass any configuration file and don't need to pass a list of allowed domains to resolve:
```bash
./iwasm --addr-pool=<addr-pool to bind> src/mosquitto.aot
```