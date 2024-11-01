// simple program that will print "stairs" with `*` symbol 
import dflag

// @[dflag: 'non-strict']
@[callback: 'handler']
struct Test {
	help	bool			@[flag; short: 'h']
	stairs	int	 = 1		@[short: 's']
}

fn (t &Test) handler() {
	if t.help || t.stairs == 1{
		println("Usage: ./program [OPTION][VALUE]")
		println("./program --stairs 10")
		exit(1)
	}
	mut text := ''
	for i := 1; i <= t.stairs; i++ {
		for j := 0; j<i; j++ {
			text += '*'
		}
		if i != t.stairs {
			text += '\n'
		}
	}
	
	println(text)
}

fn main(){
	dflag.handle[Test]()
}