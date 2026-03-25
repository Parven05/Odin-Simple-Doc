package test

import "core:fmt"

@(private = "file")
@(objc_name = "test")
foreign_proc :: proc "c" (x: i32) -> i32 {
	return x * 2
}

foo :: proc() {
	//nothing
}

Transform :: struct {
	pos_x, pos_y: f32,
}

RenderCallback :: proc(dt: f32)
