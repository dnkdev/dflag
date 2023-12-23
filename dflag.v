module dflag

import os

pub type HandlerFn = fn ()

pub struct Type[T] {
pub mut:
	// name string
	// short string
	// flag bool
	value T
	usage string
}

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
	parent           &T
	cli_name         string
	handler          string
	options          []CommandOption
	extra_args       []string
	is_compact_flags bool
	// cmd_count         int
	// exe_path          string
}

pub fn handle[T]() &T {
	mut cli := CliParams[T]{
		parent: &T{}
	}
	cli.parse_struct()
	cli.parse_args(os.args) or {
		eprintln('error: ${err}')
		exit(1)
	}
	$if dflag_debug ? {
		dump(cli)
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

@[direct_array_access]
fn (mut cli CliParams[T]) parse_args(args []string) ! {
	// cli.exe_path = os.args[0]
	// cli.cmd_count = os.args.len - 1
	mut is_arg_flag_value := false
	mut os_args := args.clone()
	os_args.delete(0) // delete the path

	if cli.is_compact_flags {
		for i in 0 .. os_args.len {
			input_flag := os_args[i]
			if !input_flag.starts_with('--') && input_flag.starts_with('-') && input_flag.len > 2 {
				os_args.delete(i)
				os_args << input_flag.all_after('-').split('').map('-' + it)
			}
		}
		$if dflag_debug ? {
			dump(os_args)
		}
	}
	for i in 0 .. os_args.len {
		input_flag := os_args[i]
		input_flag_delim := if input_flag.starts_with('--') {
			'--'
		} else if input_flag.starts_with('-') {
			'-'
		} else {
			if !is_arg_flag_value {
				cli.extra_args << input_flag
			}
			is_arg_flag_value = false
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
					is_arg_flag_value = true
				} else {
					value = 'true'
				}
				option.value = value.str()
				$for field in T.fields {
					if field.name == option.name {
						$if field.typ is Type[string] {
							cli.parent.$(field.name).value = value.str()
							cli.parent.$(field.name).usage = option.usage
						} $else $if field.typ is Type[bool] {
							if option.value == 'true' {
								cli.parent.$(field.name).value = true
							} else {
								cli.parent.$(field.name).value = false
							}
							cli.parent.$(field.name).usage = option.usage
						} $else $if field.typ is Type[int] {
							cli.parent.$(field.name).value = value.int()
							cli.parent.$(field.name).usage = option.usage
						} $else $if field.typ is Type[[]string] {
							cli.parent.$(field.name).value << value.str()
							cli.parent.$(field.name).usage = option.usage
						}$else $if field.typ is Type[i64] {
							cli.parent.$(field.name).value = value.i64()
							cli.parent.$(field.name).usage = option.usage
						} $else $if field.typ is Type[u64] {
							cli.parent.$(field.name).value = value.u64()
							cli.parent.$(field.name).usage = option.usage
						} $else $if field.typ is Type[u32] {
							cli.parent.$(field.name).value = value.u32()
							cli.parent.$(field.name).usage = option.usage
						} $else $if field.typ is Type[f32] {
							cli.parent.$(field.name).value = value.f32()
							cli.parent.$(field.name).usage = option.usage
						} $else $if field.typ is Type[f64] {
							cli.parent.$(field.name).value = value.f64()
							cli.parent.$(field.name).usage = option.usage
						} $else {
							eprintln('error: `${field.name}` type is not acceptable. Use `@[nocmd]` to skip, or type of `dflag.Type[T]`')
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

fn (mut cli CliParams[T]) parse_struct() {
	$for s_attr in T.attributes {
		if s_attr.name == 'cli_name' {
			cli.cli_name = s_attr.arg
		} else if s_attr.name == 'callback' {
			cli.handler = s_attr.arg
		} else if s_attr.name == 'compact_flags' {
			cli.is_compact_flags = true
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
						option.usage = attr[1..].join(':').trim_indent()
					}
					'flag' {
						$if field.typ !is bool && field.typ !is Type[bool] {
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
