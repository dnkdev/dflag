module dflag

import os

// Param represents the parsed struct fields, or params
struct Param {
mut:
	long      string
	short     string
	is_flag   bool
}

struct Settings {
mut:
	short_opt struct {
		mut:
		is_positional bool = true
		is_single_char bool 
		is_eq_sign_values bool // -f=example.txt
		is_concat_values bool // -fexample.txt
		is_compact_flags  bool // -vds same as -v -d -s
	}
	long_opt struct {
		mut:
		is_positional bool = true
		is_eq_sign_values bool
	}
}

// 	`non-strict` - allow to collect all input arguments that didn't match to `extra_opt` 
//  `strict` - default mode. returns an error if unrecognized option is given. 
enum Mode {
	strict
	non_strict
}

//  `operands` are all positional arguments after all your program's options. 
//  your options and operands can be separeted with `--` argument `./example -v -ovalue -ctext -- --patern -v example.txt`
//  in example above the  `--pattern`, `-v` and `example.txt` are treated separately from  `-ctext` `-ovalue` and `-v` as positional extra arguments
//  reffering to https://pubs.opengroup.org/onlinepubs/7908799/xbd/utilconv.html#usg
struct CliParams[T] {
mut:
	parent            &T // struct to parse
	cursor 			  int
	args			  []string // args to parse
	settings		  Settings
	params         	  []Param // @[str:skip] // array of parsed struct
	parsed            []Argument // array of parsed args
	operands          []string  
	handler           string
	mode              Mode = .strict
}

// handle - the main function to call and pass your struct as generic type
pub fn handle[T]() &T {
	mut cli := CliParams[T]{
		parent: &T{}
	}
	$if dflag_debug ? {
		println('[dflag_debug][${@FILE_LINE}] parsing `${T.name}` struct')
	}
	cli.parse_struct()
	mut os_args := os.args.clone()
	os_args.delete(0) // delete the path
	cli.args = os_args
	$if dflag_debug ? {
		println('[dflag_debug][${@FILE_LINE}] parsing args ${os_args}')
	}
	cli.parse_args() or {
		eprintln('\033[31merror\033[0m: ${err}')
		exit(1)
	}
	$if dflag_debug ? {
		println('[dflag_debug][${@FILE_LINE}] result struct: ${cli}')
	}
	cli.call_handler()
	return cli.parent
}

fn (mut cli CliParams[T]) call_handler() {
	if cli.handler.len > 0 {
		$for method in T.methods {
			if method.name == cli.handler {
				cli.parent.$method()
				return
			}
		}
	}
}

fn (mut cli CliParams[T]) can_peek() bool {
	if cli.cursor + 1 < cli.args.len {
		return true
	} else {
		return false
	}
}

fn (mut cli CliParams[T]) peek() string{
	return cli.args[cli.cursor + 1]
}

// Argument represents the parsed input argument
struct Argument {
mut:
	name string
	text string
	dash_str string
	value string
	is_flag bool
}

fn (mut cli CliParams[T]) parse_short_opt(mut arg Argument) !{
	if cli.settings.short_opt.is_eq_sign_values {
		if arg.text.contains('=') {
			opt := arg.text.all_before('=').all_after(arg.dash_str)
			val := arg.text.all_after('=')
			for mut param in cli.params {
				if !param.is_flag && param.short == opt {
					println('set ${opt} ${val}')
					arg.value = val
					arg.name = opt
					return
				}
			}
		}
	}
	if cli.settings.short_opt.is_concat_values {
		for mut param in cli.params {
			if !param.is_flag && param.short.len != arg.name.len && arg.text.starts_with('${arg.dash_str}${param.short}') {
				// println('${arg.dash_str}${param.short} == ${arg.text}')
				arg.value = arg.text.all_after('${arg.dash_str}${param.short}')
				arg.name = param.short
				return
			}
		}
	}
	if cli.settings.short_opt.is_positional {
		for mut param in cli.params {
			println('${arg.text}')
			if !param.is_flag && param.short == arg.text.all_after(arg.dash_str) {
				if cli.can_peek(){
					arg.value = cli.peek()
					cli.cursor++
				}
				else {
					return error('need a value for `${arg.dash_str}${param.short}`')
				}
				return
			}
		}
	}
	if cli.settings.short_opt.is_compact_flags{
		opt_name := arg.text.all_after(arg.dash_str)
		mut founds := 0//[]&Param{};
		outer: for c in opt_name {
			// println(c.ascii_str())
			for mut param in cli.params {
				if param.is_flag && param.short == c.ascii_str() {
					founds++
					// unsafe {
					// 	founds << &param
					// }
					continue outer
				}
			}
			// if cli.mode == .strict {
				return error('unrecognized flag `${c.ascii_str()}` in option `${arg.text}`')
			// }
		}
		// println('${founds.len} len and ${opt_name.len}')
		if founds == opt_name.len {
			arg.value = 'true'
			arg.is_flag = true
			// for mut param in founds {
			// 	println('modifying ${param.long}')
			// 	// arg.value = 'true'
			// }
			return
		}
	}

	for mut param in cli.params {
		if param.is_flag && param.short == arg.text.all_after(arg.dash_str) {
			arg.value = 'true'
			arg.is_flag = true
			return
		}
	}

	if cli.mode == .strict {
		return error('unrecognized option `${arg.text}`')
	}
}

fn (mut cli CliParams[T]) parse_long_opt(mut arg Argument) !{
	if cli.settings.long_opt.is_eq_sign_values {
		if arg.text.contains('=') {
			opt := arg.text.all_before('=').all_after(arg.dash_str)
			val := arg.text.all_after('=')
			for mut param in cli.params {
				if !param.is_flag && param.long == opt {
					arg.name = opt
					arg.value = val
					return
				}
			}
		}
	}
	if cli.settings.long_opt.is_positional {
		for mut param in cli.params {
			if !param.is_flag && param.long == arg.text.all_after(arg.dash_str) {
				if cli.can_peek(){
					arg.value = cli.peek()
					cli.cursor++
				}
				else {
					return error('need a value for `${arg.text}`')
				}
				return
			}
		}
	}
	for mut param in cli.params {
		if param.is_flag && param.long == arg.text.all_after(arg.dash_str) {
			arg.value = 'true'
			arg.is_flag = true
			return
		}
	}
	if cli.mode == .strict {
		return error('unrecognized option `${arg.text}`')
	}
}

@[direct_array_access]
fn (mut cli CliParams[T]) parse_args() ! {

	if cli.settings.short_opt.is_single_char {
		for mut param in cli.params {
			if param.short.len > 1 {
				return error('`single_char` attribute means length of short is a single char. [you have: `-${param.short}` at `${param.long}` field]')
			}
		}
	}
	if cli.settings.short_opt.is_compact_flags {
		for mut param in cli.params {
			if param.short.len > 1 {
				return error('`compact` boolean flags can be used only with single char shorts. [you have `-${param.short}` at `${param.long}` field]')
			}
		}
	}
	for i := 0 ; cli.cursor < cli.args.len ; {
		i = cli.cursor
		if cli.args[i] == '--' {
			if i + 1 < cli.args.len {
				cli.operands = cli.args[i + 1..]
			}
			break
		}
		mut arg := Argument {
			text:cli.args[i]
			dash_str: if cli.args[i].starts_with('--') {
					'--'
				} else if cli.args[i].starts_with('-') {
					'-'
				} else {''}
		}
		arg.name = arg.text.all_after(arg.dash_str)
		if arg.dash_str.len == 1 {
			cli.parse_short_opt(mut arg)!
			
		}
		else if arg.dash_str.len == 2 {
			cli.parse_long_opt(mut arg)!
		}
		else {}

		cli.parsed << arg
		
		cli.cursor++
	}
	// println(cli)
//
	// println(cli.parsed)
	outer: for mut arg in cli.parsed {
		for param in cli.params {
			if (arg.is_flag && param.is_flag) && (cli.settings.short_opt.is_compact_flags || arg.name == param.long || arg.name == param.short){
				// println('${arg.dash_str}${arg.name} is flag ${param.long} ${arg.name == param.short}')

				mut flag_args := []u8{}
				if arg.name.len > 1  && cli.settings.short_opt.is_compact_flags && arg.dash_str.len == 1{
					for f in arg.name {
						flag_args << f
					}
				}else {
					flag_args << arg.name.bytes()[0]
				}
				flag_for: for flag in flag_args {
					$for field in T.fields {
						$if field.typ is bool {
							if field.name == param.long && param.short == flag.ascii_str(){
								// println('setting ${field.name} | ${param.long} ${param.short} ${flag.ascii_str()} ${flag_args.map(it.ascii_str())}')
								cli.parent.$(field.name) = true
								continue flag_for
							}
						}
					}
				}
			}
			else if arg.name == param.long || arg.name == param.short {
				arg.name = param.long
				$for field in T.fields {
					if field.name == arg.name {
						// println('processing ${field.name}')
						$if field.typ is string {
							cli.parent.$(field.name) = arg.value.str()
						} 
						$else $if field.typ is bool {
							return error('field `${field.name}` is not a boolean flag. Add attribute `flag` or `nocmd` to skip.')
						} $else $if field.typ is int {
							cli.parent.$(field.name) = arg.value.int()
						} $else $if field.typ is []string {
							cli.parent.$(field.name) << arg.value.str()
						} $else $if field.typ is i64 {
							cli.parent.$(field.name) = arg.value.i64()
						} $else $if field.typ is u64 {
							cli.parent.$(field.name) = arg.value.u64()
						} $else $if field.typ is u32 {
							cli.parent.$(field.name) = arg.value.u32()
						} $else $if field.typ is f32 {
							cli.parent.$(field.name) = arg.value.f32()
						} $else $if field.typ is f64 {
							cli.parent.$(field.name) = arg.value.f64()
						} $else {
							return error('`${field.name}` type is not acceptable. Set `@[nocmd]` attribute to skip.')
						}
					}
				}
			}
		}
	}
	// cli.add_extra_arguments()
}

// fn (mut cli CliParams[T]) add_extra_options() {
// 	$for field in T.fields {
// 		$if field.typ is []string {
// 			if 'extra_opts' in field.attrs {
// 				cli.parent.$(field.name) = cli.operands
// 			}
// 		}
// 	}
// }

fn parse_attr_arg_line(l string) []string {
	mut values := l.split(',')
	for mut v in values {
		v = v.trim_indent()
	}
	return values
}

fn (mut cli CliParams[T]) parse_struct() {
	$for s_attr in T.attributes {
		// println(s_attr)
		match s_attr.name {
			'dflag', 'mode' {
				match s_attr.arg {
					'non-strict'{
						cli.mode = .non_strict
					}
					else {
						cli.mode = .strict
					}
				}
			}
			'callback'{
				cli.handler = s_attr.arg
			}
			'short_opt'{
				values := parse_attr_arg_line(s_attr.arg)
				for v in values {
					match v {
						'positional'{
							cli.settings.short_opt.is_positional = true
						}
						'single_char'{
							cli.settings.short_opt.is_single_char = true
						}
						'compact'{
							cli.settings.short_opt.is_compact_flags = true
						}
						'eq_sign'{
							cli.settings.short_opt.is_eq_sign_values = true
						}
						'concat'{
							cli.settings.short_opt.is_concat_values = true
						}
						else{continue}
					}
				}
			}
			'long_opt' {
				values := parse_attr_arg_line(s_attr.arg)
				for v in values {
					match v {
						'positional'{
							cli.settings.long_opt.is_positional = true
						}
						'eq_sign'{
							cli.settings.long_opt.is_eq_sign_values = true
						}
						else {continue}
					}
				}
			}
			else {}
		}
	}

	$for field in T.fields {

		if field.attrs.len == 0 {
			// do nothing if no attributes
		} else if 'extra_opts' in field.attrs {
			$if field.typ !is []string {
				panic('`extra_opts` must be `[]string` type [${T.name}.${field.name}]')
			}
		} else if 'nocmd' !in field.attrs {
			mut option := Param{}
			option.long = field.name

			for full_attr in field.attrs {
				attr := full_attr.split(':')
				match attr[0].trim_indent() {
					'short' {
						option.short = attr[1].trim_indent()
					}
					'flag' {
						$if field.typ !is bool {
							panic('`flag` fields must be `bool` type [${T.name}.${field.name}]')
						}
						option.is_flag = true
					}
					else {}
				}
			}

			cli.params << option
		}
	}
}
