# Tests

## Running

The Mosquitto test suite can be invoked using either of

```
make test
make check
```

The tests run in series and due to the nature of some of the tests being made
can take a while.

## Parallel Tests

To run the tests with some parallelism, use

```
make ptest
```

This runs up to 20 tests in parallel at once, yielding much faster overall run
time at the expense of having up to 20 instances of Python running at once.
This is not a particularly CPU intensive option, but does require more memory
and may be unsuitable on e.g. a Raspberry Pi.

## Dependencies

The tests require Python 3 and CUnit to be installed.

# Run tests WASM
There are various adaptations of the test suite to run with WASM. Currently, Unit Tests cannot be compiled as the `CUnit` library depends on `setjmp` which is not supported by WASI. However, there is work in progress and maybe soon, we can also run unit tests in WASM.

Regarding the other tests, you can set the flag `wasm` in `test/mosq_test.py` to `True` to run tests with a WASM broker. Note, that this assumes that you have a `WAMR` runtime called `iwasm` in the root of this repository.

Then, run the tests using
```bash
make RUNTARGET=WASM test
```

## Current state of the tests in WASM
* broker: Tests pass except those testing signal handling
* client: Tests work in general; not possible from stdinput
* lib: Tests are working (if compiled without THREADING): use static instead of shared library
* old: not covered / might be working or not
* random: not working out of the box as plugin and websocket support is missing; can made be running but is not a clear test case anyway
* ssl: work in general except for tests regarding CRL
* unit: tests are not yet working due to missing working version of CUnit in WASM