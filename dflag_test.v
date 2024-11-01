module dflag

@[dflag: 'non-strict'] 
@[callback: 'handler_func']
@[short_opt: 'positional, eq_sign, concat, compact, single-char']
@[long_opt: 'positional, eq_sign']
struct DTest {
mut:
	help        bool     @[flag; short: 'h'] 
	print       []string @[short: 'p'] 
	number      int      @[short: 'n'] 
	float       f32      @[short: 'f']
	boolean     bool     @[flag; short: 'b']
	verbose     bool     @[flag; short: 'v']
	@dump       bool     @[flag; short: 'd']
	extra  		[]string @[extra_opts] 
	operands	[]string @[operands] 
	empty       string   @[nocmd] 
	empty_array []string		
}

fn (d &DTest) handler_func() {
	assert true
}

fn test_parse_struct() {
	mut cli := CliParams[DTest]{
		parent: &DTest{}
	}
	cli.parse_struct()
	assert cli.params.len == 7
	assert cli.params[0].long == 'help'
	assert cli.params[0].is_flag
	assert cli.params[6].is_flag
	assert cli.params[6].short == 'd'
	assert cli.settings.short_opt.is_compact_flags
	assert cli.settings.short_opt.is_concat_values
	assert cli.settings.short_opt.is_eq_sign_values
	assert cli.settings.long_opt.is_eq_sign_values
	assert cli.handler == 'handler_func'
}

fn test_parse_args() {
	mut cli := CliParams[DTest]{
		parent: &DTest{}
	}
	cli.parse_struct()
	cli.args = ['-p','Hello World', '-vdh' '-n', '123', '-f','3.3', '-b', 'dummy']
	cli.parse_args() or {panic(err)}
	assert cli.parent.print[0] == 'Hello World'
	assert cli.parent.verbose
	assert cli.parent.@dump
	assert cli.parent.help
	assert cli.parent.number == 123
	assert cli.parent.float == 3.3
	assert cli.parent.boolean == true
	assert cli.parent.operands.len == 1
}

fn test_call_hanlder(){
	mut cli := CliParams[DTest]{
		parent: &DTest{}
	}
	cli.parse_struct()
	cli.call_handler()
}