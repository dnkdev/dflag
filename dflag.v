module dflag

import os

pub type HandlerFn = fn ()

struct CommandOption {
mut:
	name  string
	short string
	usage string
	value string
	flag  bool // if true then there is no need for an value for this option, just flag
}

struct CliParams[T] {
mut:
	parent            T
	cli_name          string
	handler           string
	options           []CommandOption
	extra_args        []string
	is_compact_shorts bool
	// cmd_count         int
	// exe_path          string
}

pub fn handle[T]() T {
	mut cli := CliParams[T]{}
	cli.parse_struct(mut cli.parent)
	cli.parse_args() or {
		eprintln('error: ${err}')
		exit(1)
	}
	cli.call_handler()
	res := cli.parent
	// println(cli)
	return res
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

@[direct_array_access]
fn (mut cli CliParams[T]) parse_args() ! {
	// cli.exe_path = os.args[0]
	// cli.cmd_count = os.args.len - 1
	mut is_flag_value := false
	mut os_args := os.args.clone()
	os_args.delete(0) // delete the path
	if cli.is_compact_shorts {
		for i in 0 .. os_args.len {
			input_flag := os_args[i]
			if !input_flag.starts_with('--') && input_flag.starts_with('-') && input_flag.len > 2 {
				os_args.delete(i)
				os_args << input_flag.all_after('-').split('').map('-' + it)
			}
		}
		// println(os_args)
	}
	for i in 0 .. os_args.len {
		input_flag := os_args[i]
		input_flag_delim := if input_flag.starts_with('--') {
			'--'
		} else if input_flag.starts_with('-') {
			'-'
		} else {
			if !is_flag_value {
				cli.extra_args << input_flag
			}
			is_flag_value = false
			continue
		}
		input_flag_name := input_flag.all_after(input_flag_delim)

		mut is_valid_flag := false
		for mut option in cli.options {
			flag_name := if input_flag_delim == '--' { option.name } else { option.short }
			if flag_name == input_flag_name {
				is_valid_flag = true
				mut value := ''
				if !option.flag {
					if i + 1 >= os_args.len {
						return error('option `${input_flag_delim}${flag_name}` requires a value')
					}
					val := os_args[i + 1]
					if val.starts_with('-') {
						return error('wrong `${option.name}` option value `${input_flag_delim}${flag_name} ${val}`')
					}
					value = val
					is_flag_value = true
				} else {
					value = 'true'
				}
				option.value = value.str()
				$for field in T.fields {
					if field.name == option.name {
						$if field.typ is string {
							cli.parent.$(field.name) = value.str()
						} $else $if field.typ is bool {
							cli.parent.$(field.name) = if option.value == 'true' {
								true
							} else {
								false
							}
						} $else $if field.typ is int {
							cli.parent.$(field.name) = value.int()
						} $else $if field.typ is i64 {
							cli.parent.$(field.name) = value.i64()
						} $else $if field.typ is u64 {
							cli.parent.$(field.name) = value.u64()
						}
					}
				}
			}
		}
		if !is_valid_flag {
			return error('unknown input option: `${input_flag}`')
		}
	}
	cli.add_extra_arguments()
}

fn (mut cli CliParams[T]) add_extra_arguments() {
	$for field in T.fields {
		$if field.typ is []string {
			if 'extra_args' in field.attrs {
				cli.parent.$(field.name) = cli.extra_args
			}
		}
	}
}

fn (mut cli CliParams[T]) parse_struct(mut parent T) {
	cli.parent = parent
	$for s_attr in T.attributes {
		if s_attr.name == 'cli_name' {
			cli.cli_name = s_attr.arg
		} else if s_attr.name == 'callback' {
			cli.handler = s_attr.arg
		} else if s_attr.name == 'compact_short_names' {
			cli.is_compact_shorts = true
		}
	}
	$for field in T.fields {
		if field.attrs.len == 0 {
			// do nothing if no attributes
		} else if 'extra_args' in field.attrs {
			$if field.typ !is []string {
				panic('`extra_args` must be `[]string` type [${T.name}.${field.name}]')
			}
		} else if 'nocmd' !in field.attrs {
			mut option := CommandOption{}
			option.name = field.name

			for full_attr in field.attrs {
				attr := full_attr.split(':')
				match attr[0].trim_indent() {
					'short' {
						option.short = attr[1].trim_indent()
					}
					'usage' {
						option.usage = attr[1].trim_indent()
					}
					'flag' {
						$if field.typ !is bool {
							panic('`flag` fields must be `bool` type [${T.name}.${field.name}]')
						}
						option.flag = true
					}
					else {}
				}
			}
			cli.options << option
		}
	}
}
