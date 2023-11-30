module main

import dflag

@[callback: 'handler_func']
@[compact_short_names]
struct DTest {
mut:
	help    bool     @[flag; short: 'h']
	print   string   @[short: 'p']
	number  int      @[short: 'n']
	verbose bool     @[flag; short: 'v']
	@dump   bool     @[flag; short: 'd']
	files   []string @[extra_args]
	empty   string   @[nocmd] // `nocmd` = just skipping in processing by `dflag` module (@[my_custom_attr;nocmd])
	whats   []string // no attributes will skip processing also
}

fn main() {
	dflag.handle[DTest]()
}

fn (d DTest) handler_func() {
	if d == DTest{} || d.help {
		print_help()
		return
	}
	if d.@dump {
		dump(d)
	}
	if d.print != '' {
		if d.verbose {
			println('verbose print!!')
		}
		println('Print the text: ${d.print}')
	}
}

fn print_help() {
	println('Cool CLI Application Doing Cool Stuff\nUsage: cli [OPTION] [VALUE] [...ARGS]\n
OPTIONS:
	--help    -h	This Help Text
	--print   -p	Print text
	--verbose -v	Verbose output')
}
