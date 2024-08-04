EXAMPLES_INPUT=$(wildcard examples/src/*.c)
EXAMPLES_OUTPUT=$(addprefix examples/out/,$(notdir $(basename $(EXAMPLES_INPUT))))

build_examples: $(EXAMPLES_OUTPUT) 

examples/out/%: build_codin examples/src/%.c
	./codin examples/src/$*.c $@
	@echo '-------------------------------'

build_codin: lib/lib.o codin

codin: $(wildcard ./*.odin) $(wildcard ./ambles/*.fasm) 
	odin build ../codin -error-pos-style:unix -debug
lib/lib.o: $(wildcard lib/*.odin)
	odin build lib -error-pos-style:unix -build-mode:object -default-to-nil-allocator -no-entry-point -no-crt -out:lib/lib.o
clean:
	rm codin lib/lib.o
	rm examples/out/*

