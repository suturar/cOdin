EXAMPLES_INPUT=$(wildcard input/*.c)
EXAMPLES_OUTPUT=$(addprefix output/,$(notdir $(basename $(EXAMPLES_INPUT))))

build_examples: $(EXAMPLES_OUTPUT) 

output/%: build_codin input/%.c
	./codin input/$*.c $@
	@echo '-------------------------------'

build_codin: lib/lib.o codin

codin: $(wildcard ./*.odin) $(wildcard ./ambles/*.fasm) 
	odin build ../codin -error-pos-style:unix -debug
lib/lib.o: $(wildcard lib/*.odin)
	odin build lib -error-pos-style:unix -build-mode:object -default-to-nil-allocator -no-entry-point -no-crt -out:lib/lib.o
clean:
	rm codin lib/lib.o
	rm output/*

