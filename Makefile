OCAML_LIBDIR?=`ocamlfind printconf destdir`
OCAML_FIND ?= ocamlfind

ROCKS_VERSION=4.3.1
ROCKS_LIB=rocksdb
ROCKS_INSTALL=/home/chet/Hack/IL/rocksdb-$(ROCKS_VERSION)
ROCKS_LIBDIR=$(ROCKS_INSTALL)/lib

export ROCKS_LIB ROCKS_LIBDIR

ROCKS_LINKFLAGS = \
  -lflag -cclib -lflag -Wl,-rpath=$(ROCKS_LIBDIR) \
  -lflags -cclib,-L$(ROCKS_LIBDIR),-cclib,-l$(ROCKS_LIB)


build:
	ocamlbuild -use-ocamlfind $(ROCKS_LINKFLAGS) rocks.inferred.mli rocks.cma rocks.cmxa rocks.cmxs rocks_options.inferred.mli

test:
	ocamlbuild -use-ocamlfind $(ROCKS_LINKFLAGS) rocks_test.native rocks.inferred.mli rocks.cma rocks.cmxa rocks.cmxs

clean:
	ocamlbuild -clean

install:
	mkdir -p $(OCAML_LIBDIR)
	$(OCAML_FIND) install rocks -destdir $(OCAML_LIBDIR) _build/META \
	 _build/rocks.a \
	 _build/rocks.cma \
	 _build/rocks.cmi \
	 _build/rocks.cmx \
	 _build/rocks.cmxa \
	 _build/rocks.cmxs

uninstall:
	$(OCAML_FIND) remove rocks -destdir $(OCAML_LIBDIR)
