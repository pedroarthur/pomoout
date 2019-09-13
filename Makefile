output_binary = tgt/main/cmake/pomoout

all: $(output_binary)

$(output_binary): $(shell find src/main)
	cmake --debug -S src/tool/cmake/ -B tgt/main/cmake/ src/main/
	make -C tgt/main/cmake/

run: $(output_binary)
	$(output_binary)
