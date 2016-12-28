CXXFLAGS= -g -W -Wextra -Wall -Wsign-compare -Wshadow -Wno-unused-parameter -std=c++11  -DROCKSDB_PLATFORM_POSIX -DROCKSDB_LIB_IO_POSIX  -DOS_LINUX -fno-builtin-memcmp -DROCKSDB_FALLOCATE_PRESENT -DSNAPPY -DGFLAGS=gflags -DZLIB -DBZIP2 -DLZ4 -DNUMA -DROCKSDB_MALLOC_USABLE_SIZE -DROCKSDB_PTHREAD_ADAPTIVE_MUTEX -DROCKSDB_BACKTRACE -march=native   -isystem ./third-party/gtest-1.7.0/fused-src -O2 -fno-omit-frame-pointer -momit-leaf-frame-pointer -DNDEBUG -Woverloaded-virtual -Wnon-virtual-dtor -Wno-missing-field-initializers -fPIC -I$(ROCKS_INSTALL)/include

all: build

build: librocks-extra.so

librocks-extra.so: morec.cc morec.h
	g++ -Wl,--no-as-needed -shared -Wl,-soname -Wl,librocks-extra.so $(CXXFLAGS) -o librocks-extra.so morec.cc

clean::
	rm -f *.o *.so

install:: librocks-extra.so
	cp librocks-extra.so $(ROCKS_LIBDIR)/librocks-extra.so

uninstall::
	rm -f $(ROCKS_LIBDIR)/librocks-extra.so
