module dflag

@[callback: 'handler_func']
@[compact_flags]
struct DTest {
mut:
	help        bool     @[flag; short: 'h']
	print       []string @[short: 'p']
	number      int      @[short: 'n']
	float       f32      @[short: 'f']
	boolean     bool     @[short: 'b']
	verbose     bool     @[flag; short: 'v']
	@dump       bool     @[flag; short: 'd']
	files       []string @[extra_args]
	empty       string   @[nocmd] // `nocmd` = just skipping in processing by `dflag` module (@[my_custom_attr;nocmd])
	empty_array []string // no attributes will skip processing also		
}
fn (d &DTest) handler_func() {
	assert true
}

fn test_parse_struct() {
	mut cli := CliParams[DTest]{
		parent: &DTest{}
	}
	cli.parse_struct()
	assert cli.options.len == 7
	assert cli.options[0].name == 'help'
	assert cli.options[0].is_flag
	assert cli.options[6].is_flag
	assert cli.options[6].short == 'd'
	assert cli.is_compact_flags
	assert cli.handler == 'handler_func'
}

fn test_parse_args() {
	mut cli := CliParams[DTest]{
		parent: &DTest{}
	}
	cli.parse_struct()
	cli.parse_args(['.','-p','Hello World', '-vdh' '-n', '123', '-f','3.3', '-b','true']) or {panic(err)}
	assert cli.parent.print[0] == 'Hello World'
	assert cli.parent.verbose
	assert cli.parent.@dump
	assert cli.parent.help
	assert cli.parent.number == 123
	assert cli.parent.float == 3.3
	assert cli.parent.boolean == true
}

fn test_call_hanlder(){
	mut cli := CliParams[DTest]{
		parent: &DTest{}
	}
	cli.parse_struct()
	cli.call_handler()
}