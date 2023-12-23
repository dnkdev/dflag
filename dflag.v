module dflag

import os

struct CommandOption {
mut:
	name  string
	short string
	value string
	is_flag  bool // if true then there is no need for an value for this option, just flag
}

struct CliParams[T] {
mut:
	parent           &T
	handler          string
	options          []CommandOption
	extra_args       []string
	is_compact_flags bool
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
				if !option.is_flag {
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
						$if field.typ is string {
							cli.parent.$(field.name) = value.str()
						} $else $if field.typ is bool {
							if option.value == 'true' {
								cli.parent.$(field.name) = true
							} else {
								cli.parent.$(field.name) = false
							}
						} $else $if field.typ is int {
							cli.parent.$(field.name) = value.int()
						} $else $if field.typ is []string {
							cli.parent.$(field.name) << value.str()
						} $else $if field.typ is i64 {
							cli.parent.$(field.name) = value.i64()
						} $else $if field.typ is u64 {
							cli.parent.$(field.name) = value.u64()
						} $else $if field.typ is u32 {
							cli.parent.$(field.name) = value.u32()
						} $else $if field.typ is f32 {
							cli.parent.$(field.name) = value.f32()
						} $else $if field.typ is f64 {
							cli.parent.$(field.name) = value.f64()
						} $else {
							eprintln('error: `${field.name}` type is not acceptable. Set `@[nocmd]` attribute to skip.')
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
		if s_attr.name == 'callback' {
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
					'flag' {
						$if field.typ !is bool { 
							panic('`flag` fields must be `bool` type [${T.name}.${field.name}]')
						}
						option.is_flag = true
					}
					else {}
				}
			}

			cli.options << option
		}
	}
}
