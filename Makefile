.PHONY : clean

target=gcd

$(target): $(target).ml
	ocamlfind ocamlopt -o irgen -linkpkg -package llvm $(target).ml \
		&& ./irgen > out/$(target).out

run: out/$(target).out
	lli out/$(target).out

clean:
	rm -rf *.cmi *.cmx *.o irgen
