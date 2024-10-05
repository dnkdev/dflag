module main

import dflag

// `callback` - struct method to call it for processing the result
// `compact_flags` - allows to write multiple flags within one-dash(-):
// 		`.. -vds ..` which also is `.. -v -d -s ..`
// `eq_sign_values` - additionally allows to write value for long (two dash) options right away after `=` sign:
//  	`./example --print="Hello World" --number=10`
@[callback: 'handler_func']
@[compact_flags]
@[eq_sign_values]
struct DTest {
mut:
	help        bool     @[flag; short: 'h'] //
	print       []string @[short: 'p'] // array allows using option multiple times
	number      int      @[short: 'n'] // not a flag, so requires a value 
	float       f32      @[short: 'f']
	boolean     bool     @[short: 'b']
	verbose     bool     @[flag; short: 'v']
	@dump       bool     @[flag; short: 'd']
	files       []string @[extra_args] // `extra_args` collects all the rest arguments
	empty       string   @[nocmd] // `nocmd` = skipping in processing by `dflag` module (@[my_custom_attr;nocmd])
	empty_array []string // no attributes will skip processing also		
}

fn main() {
	dflag.handle[DTest]()
}

fn (d &DTest) handler_func() {
	if d == DTest{} || d.help {
		print_help()
		return
	}
	if d.@dump {
		dump(d)
	}
	if d.verbose {
		println('verbose flag detected!')
	}
	println('bool is ${d.boolean}')

	if d.number != 0 {
		println('number is: `${d.number}` (${typeof(d.number).name})')
	}
	if d.float != 0.0 {
		println('float is `${d.float}` (${typeof(d.float).name})')
	}
	for print in d.print {
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
