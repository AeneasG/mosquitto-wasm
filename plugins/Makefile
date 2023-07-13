DIRS= \
		auth-by-ip \
		deny-protocol-version \
		dynamic-security \
		message-timestamp \
		payload-modification

.PHONY : all binary check clean reallyclean test install uninstall

all :
# don't build plugins for WASM target
ifneq ($(TARGET_WASM),yes))
	set -e; for d in ${DIRS}; do $(MAKE) -C $${d}; done
endif

binary :
	set -e; for d in ${DIRS}; do $(MAKE) -C $${d} $@; done

clean :
	set -e; for d in ${DIRS}; do $(MAKE) -C $${d} $@; done

reallyclean :
	set -e; for d in ${DIRS}; do $(MAKE) -C $${d} $@; done

check : test
test :
	set -e; for d in ${DIRS}; do $(MAKE) -C $${d} $@; done

install :
	set -e; for d in ${DIRS}; do $(MAKE) -C $${d} $@; done

uninstall :
	set -e; for d in ${DIRS}; do $(MAKE) -C $${d} $@; done
