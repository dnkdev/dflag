`dflag` - command line option parser

Library exploits V's language compile-time capabilities to simplify creation of
CLI program.

### Quick Start

##### Install `dflag` module

`v install https://github.com/dnkdev/dflag`

##### Compile Example

`v ~/.vmodules/dflag/examples/full_example.v -o ./example`

##### Run compiled binary

`./example -f 33.1 -n 11 -p "Hello World" -vdb dummy.txt -v`
<br>
`./example -f33.1 -n=11 --random -p="Hello World" --print=Goodbye -v -d -b dummy.txt -v`

### Example Code

```v
// This example shows all possible attributes
module main

import dflag

// `dflag` attribute sets the parsing mode. Modes:
//     `non-strict` - instead of error, collects all input options that didn't match to `extra_opts` 
//     `strict` - default mode. returns an error if unrecognized option is given.
// `handler` - struct method for processing the result
// `short_opt` and `long_opt` is settings for short and long options
// short is single-dash options `-`, long option starts with double-dash `--`
//     `positional` default positional parsing, with space as delimiter. [./cl --option option_argument]
//     `non_positional` turns off positional argument parsing
//     `eq_sign` allow parse option_argument after `=` sign for option [./cl --option=option_argument]
//     `concat` allows to parse option_argument right after option [./cl -fexample.txt]
//     `compact` allows to write multiple flags within one-dash(-) ["./cl -vds .." which also is "./cl -v -d -s .."]
@[dflag: 'non-strict'] 
@[handler: 'handler_func']
@[short_opt: 'positional, eq_sign, concat, compact']
@[long_opt: 'positional, eq_sign']
struct DTest {
mut:
	help        bool     @[flag; short: 'h'] // all boolean options-flags should be marked with `flag` attribute
	print       []string @[short: 'p'] // array allows using option multiple times
	number      int      @[short: 'n'] 
	float       f32      @[short: 'f']
	boolean     bool     @[flag; short: 'b']
	verbose     bool     @[flag; short: 'v']
	@dump       bool     @[flag; short: 'd']
	extra  		[]string @[extra_opts] // `extra_opts` collects all the rest OPTIONS that didn't match. Used only with `non-strict` mode.
	operands	[]string @[operands] // `operands` collects all the rest ARGUMENTS after `--` argument or all after first arg, which is not an option
	empty       string   @[nocmd] // `nocmd` = skipping in processing by `dflag` module (@[my_custom_attr;nocmd])
	empty_array []string // no attributes will skip processing also		
}

fn main() {
	dflag.handle[DTest]() or {
		eprintln(err)
	}
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
	if d.extra.len > 0 {
		println('additional options: ${d.extra}')
	}
	if d.operands.len > 0 {
		println('operands are: ${d.operands}')
	}
}

fn print_help() {
	println('Cool CLI Application Doing Cool Stuff\nUsage: cli [OPTION] [VALUE] [...ARGS]\n
OPTIONS:
	--print   -p	Print text
	--number  -n	Show that this is number indeed
	--float   -f	Show that this is the float
FLAGS:
	--help    -h	This Help Text
	--verbose -v	Verbose output
	--boolean -b 	Is it "true" or "false"
	--dump	  -d	Dump the struct')
}
```

IDEAS:

- Only single-dash options, only double-dash
- `long:` attribute for setting a long name, instead of using just fieldname
