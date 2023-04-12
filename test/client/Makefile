.PHONY: all check test ptest clean

all :

check : test
ptest : test
test :
ifeq ($(RUNTARGET),WASM)
	./test_wasi.sh
else
	./test.sh
endif

clean:
