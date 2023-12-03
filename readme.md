## `dflag` stands for "declarative flag"

Library exploits V's language compile-time capabilities to simplify creation of CLI program. Gives the programmer the chance to write less code. Command-line interface could be described mostly in declarative style. Made for proof of concept and work at the first place, with hope that V works fine (but it is in v0.4 now in 2023).

```
v install https://github.com/dnkdev/dflag
v run ~/.vmodules/dflag/examples/simple_example.v -b true -f 33.1 -n 11 -p "Hello World" -vd dummy.txt
```

```v
module main

import dflag


// `compact_flags` - allows to write multiple flags within one-dash(-):
// 	`.. -vds ..` which also is `.. -v -d -s ..`
@[callback: 'handler_func']
@[compact_flags]
struct DTest {
mut:
	help        dflag.Type[bool]   @[flag; short: 'h']
	print       dflag.Type[string] @[short: 'p'; usage: '`cli -p "Hello World"`']
	number      dflag.Type[int]    @[short: 'n']
	float       dflag.Type[f32]    @[short: 'f']
	boolean     dflag.Type[bool]   @[short: 'b']
	verbose     dflag.Type[bool]   @[flag; short: 'v']
	@dump       dflag.Type[bool]   @[flag; short: 'd']
	files       []string           @[extra_args]
	empty       string             @[nocmd] // `nocmd` = skipping in processing by `dflag` module (@[my_custom_attr;nocmd])
	empty_array []string // no attributes will skip processing also		
}

fn main() {
	dflag.handle[DTest]()
}

fn (d &DTest) handler_func() {
	if d == DTest{} || d.help.value {
		print_help()
		return
	}
	if d.@dump.value {
		dump(d)
	}
	if d.verbose.value {
		println('verbose flag detected!')
	}
	println('bool is ${d.boolean.value}')

	if d.number.value != 0 {
		println('number is: `${d.number.value}` (${typeof(d.number.value).name})')
	}
	if d.float.value != 0.0 {
		println('float is `${d.float.value}` (${typeof(d.float.value).name})')
	}
	if d.print.value != '' {
		println('text is: `${d.print.value}` (${typeof(d.print.value).name})')
	}
	if d.files.len > 0 {
		println('additional arguments: ${d.files}')
	}
}

fn print_help() {
	println('Cool CLI Application Doing Cool Stuff\nUsage: cli [OPTION] [VALUE] [...ARGS]\n
OPTIONS:
	--help    -h	This Help Text
	--print   -p	Print text
	--verbose -v	Verbose output
	--number  -n	Show that this is number indeed
	--float   -f	Show that this is the float
	--boolean -b 	Is it "true" or "false"
	--dump	  -d	Dump the struct')
}

```

TODO: tests

TODO: accept `dflag.Type[[]string]` - same flag multiple times in command line

TODO: accept structs to add a subcommands, like `cli doc -h` `cli run -h` ?
