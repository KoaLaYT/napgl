.PHONY: clean run

clean:
	rm -rf .zig-cache zig-out

run:
	zig build run
