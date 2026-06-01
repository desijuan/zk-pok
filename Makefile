.DEFAULT_GOAL := build

build:
	zig build -Dtarget=x86-windows-gnu --summary all

clean:
	rm -rf .zig-cache zig-out zig-pkg

.PHONY: build clean
