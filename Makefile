OCAML_LIBDIR?=`ocamlfind printconf destdir`
OCAML_FIND ?= ocamlfind

ROCKS_LIB=rocksdb
ROCKS_INSTALL=/home/chet/Hack/IL-DEV/rocksdb-myrocks
ROCKS_LIBDIR=/home/chet/Hack/IL-DEV/rocksdb-myrocks/lib
ROCKS_VERSION=myrocks

#ROCKS_VERSION ?= 4.11.2
#ROCKS_INSTALL ?= /usr/local
#ROCKS_LIBDIR ?= $(ROCKS_INSTALL)/lib
#ROCKS_LIB ?= rocksdb
export ROCKS_LIB ROCKS_LIBDIR ROCKS_INSTALL

ifeq ($(ROCKS_VERSION),myrocks)
  UNIFDEF_ARGS = -D ROCKS_VERSION_MYROCKS
else
  UNIFDEF_ARGS = -U ROCKS_VERSION_MYROCKS
endif

ROCKS_LINKFLAGS = \
  -lflag -cclib -lflag -Wl,-rpath=$(ROCKS_LIBDIR) \
  -lflags -cclib,-L$(ROCKS_LIBDIR),-cclib,-l$(ROCKS_LIB) \
  -lflags -cclib,-lrocks-extra

build: rocks_options.ml
	ocamlbuild -use-ocamlfind $(ROCKS_LINKFLAGS) rocks.inferred.mli rocks.cma rocks.cmxa rocks.cmxs rocks_options.inferred.mli

test:
	ocamlbuild -use-ocamlfind $(ROCKS_LINKFLAGS) rocks_test.native rocks.inferred.mli rocks.cma rocks.cmxa rocks.cmxs
	./rocks_test.native

clean:
	make -C rocksdb-extra clean
	ocamlbuild -clean
	rm -rf aname
	rm -f rocks_options.ml

setup:: install-extra
	unifdef $(UNIFDEF_ARGS)  < rocks_options.ML \
	| ./generate_setters-and-getters.pl --rocks-install=$(ROCKS_INSTALL) \
		--c-header $(ROCKS_INSTALL)/include/rocksdb/c.h --c-header ./rocksdb-extra/morec.h > rocks_options.ml

install-extra:
	make -C rocksdb-extra build install

install:
	mkdir -p $(OCAML_LIBDIR)
	$(OCAML_FIND) install rocks -destdir $(OCAML_LIBDIR) _build/META \
	 _build/rocks.a \
	 _build/rocks.cma \
	 _build/rocks.cmi \
	 _build/rocks.cmx \
	 _build/rocks.cmxa \
	 _build/rocks.cmxs

uninstall: uninstall-extra
	$(OCAML_FIND) remove rocks -destdir $(OCAML_LIBDIR)

uninstall-extra:
	make -C rocksdb-extra uninstall
