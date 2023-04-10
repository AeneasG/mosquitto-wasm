.PHONY: all check test ptest clean

all :

check : test
ptest : test
test :
ifeq ($(RUNTARGET),WASI)
	./test_wasi.sh
else
	./test.sh
endif

clean:
