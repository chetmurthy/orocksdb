OCAML_LIBDIR?=`ocamlfind printconf destdir`
OCAML_FIND ?= ocamlfind

ROCKS_INSTALL ?= /usr/local
ROCKS_LIBDIR ?= $(ROCKS_INSTALL)/lib
ROCKS_LIB ?= rocksdb

ROCKS_LINKFLAGS = \
  -lflag -cclib -lflag -Wl,-rpath=$(ROCKS_LIBDIR) \
  -lflags -cclib,-L$(ROCKS_LIBDIR),-cclib,-l$(ROCKS_LIB)

build:
	ocamlbuild -use-ocamlfind $(ROCKS_LINKFLAGS) rocks.inferred.mli rocks.cma rocks.cmxa rocks.cmxs rocks_options.inferred.mli

test:
	ocamlbuild -use-ocamlfind $(ROCKS_LINKFLAGS) rocks_test.native rocks.inferred.mli rocks.cma rocks.cmxa rocks.cmxs
	./rocks_test.native

clean:
	ocamlbuild -clean
	rm -rf aname
	rm -f rocks_options.ml

setup::
	./generate_setters-and-getters.pl --verbose --rocks-install=$(ROCKS_INSTALL) < rocks_options.ML > rocks_options.ml

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
