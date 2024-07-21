all: codin lib.o
codin: $(wildcard ./*.odin) 
	odin build . -error-pos-style:unix -debug
lib.o: $(wildcard lib/*.odin)
	odin build lib -error-pos-style:unix -build-mode:object -default-to-nil-allocator -no-entry-point -no-crt
