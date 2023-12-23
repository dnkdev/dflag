
module main

import dflag

// `callback` - struct method to call it for processing
// `compact_flags` - allows to write multiple flags within one-dash(-):
// 	`.. -vds ..` which also is `.. -v -d -s ..`
@[callback: 'handler_func']
@[compact_flags]
struct DTest {
mut:
	help        dflag.Type[bool]   @[flag; short: 'h']
	print       dflag.Type[[]string] @[short: 'p'; usage: '`cli -p "Hello World"`']
	number      dflag.Type[int]    @[short: 'n']
	float       dflag.Type[f32]    @[short: 'f']
	boolean     dflag.Type[bool]   @[short: 'b']
	verbose     dflag.Type[bool]   @[flag; short: 'v']
	@dump       dflag.Type[bool]   @[flag; short: 'd']
	files       []string           @[extra_args]
	empty       string             @[nocmd] // `nocmd` = just skipping in processing by `dflag` module (@[my_custom_attr;nocmd])
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
	for print in d.print.value {
		if print != '' {
			println('text is: `${print}` (${typeof(print).name})')
		}
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
