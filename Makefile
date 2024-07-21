EXAMPLES_INPUT=$(wildcard input/*.c)
EXAMPLES_OUTPUT=$(addprefix output/,$(notdir $(basename $(EXAMPLES_INPUT))))

build_examples: | build_codin $(EXAMPLES_OUTPUT) 

output/%: input/%.c
	./codin $^ $@

build_codin: lib/lib.o codin

codin: $(wildcard ./*.odin) $(wildcard ./ambles/*.fasm) 
	odin build ../codin -error-pos-style:unix -debug
lib/lib.o: $(wildcard lib/*.odin)
	odin build lib -error-pos-style:unix -build-mode:object -default-to-nil-allocator -no-entry-point -no-crt -out:lib/lib.o
