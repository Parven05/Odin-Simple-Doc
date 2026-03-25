package test

sub :: proc "c" (x: int = 1, y: int) -> (value: int) {
	return x - y
}
