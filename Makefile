ERL_FILES := $(wildcard *.erl lib/*.erl)

all: $(ERL_FILES)
	make -C lib
	erlc $(ERL_FILES)

clean:
	rm -f *.beam lib/*.beam

run_tests: all
	erl -noshell -eval "eunit:test(test_client), halt()"
