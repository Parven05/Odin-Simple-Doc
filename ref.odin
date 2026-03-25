package ast_walker

import "core:fmt"
import odin_ast "core:odin/ast"
import odin_parser "core:odin/parser"
import "core:path/filepath"

test_code := #load("test.odin", string)

no_ptr_types: map[string]struct{}

main :: proc() {
	file: odin_ast.File

	file.src = test_code
	file.fullpath =
		filepath.abs("./test.odin", context.allocator) or_else panic(
			"Failed to find test.odin file.",
		)
	file.derived = &file

	parser: odin_parser.Parser

	odin_parser.parse_file(&parser, &file)

	walk_ast(&file)
}

walk_ast :: proc(file: ^odin_ast.File) {
	visitor := odin_ast.Visitor {
		visit = proc(v: ^odin_ast.Visitor, node: ^odin_ast.Node) -> ^odin_ast.Visitor {
			process_node(node)
			return v
		},
	}
	odin_ast.walk(&visitor, file)
}

process_node :: proc(node: ^odin_ast.Node) {
	if node == nil do return
	#partial switch derived in node.derived {
	case ^odin_ast.Value_Decl:
		if !has_attribute(derived.attributes, "no_ptr") {
			return
		}

		if len(derived.values) != 1 {
			panic("@no_ptr can only be applied to single declarations!")
		}
		type, is_struct := derived.values[0].derived.(^odin_ast.Struct_Type)
		if !is_struct {
			panic("@no_ptr can only be applied to structs")
		}

		no_ptr_types[derived.names[0].derived.(^odin_ast.Ident).name] = {}

	case ^odin_ast.Pointer_Type:
		ident, is_ident := derived.elem.derived.(^odin_ast.Ident)
		if is_ident && ident.name in no_ptr_types {
			print_error(ident)
		}
	case ^odin_ast.Multi_Pointer_Type:
		ident, is_ident := derived.elem.derived.(^odin_ast.Ident)
		if is_ident && ident.name in no_ptr_types {
			print_error(ident)
		}

	case ^odin_ast.Dynamic_Array_Type:
		ident, is_ident := derived.elem.derived.(^odin_ast.Ident)
		if is_ident && ident.name in no_ptr_types {
			print_error(ident)
		}
	case ^odin_ast.Array_Type:
		if derived.len == nil {
			ident, is_ident := derived.elem.derived.(^odin_ast.Ident)
			if is_ident && ident.name in no_ptr_types {
				print_error(ident)
			}
		}
	}
}

print_error :: proc(node: ^odin_ast.Ident) {
	fmt.eprintf(
		"%s(%d:%d) Error: %s is a `@no_ptr` type",
		node.pos.file,
		node.pos.line,
		node.pos.column,
		node.name,
	)
}

has_attribute :: proc(attributes: [dynamic]^odin_ast.Attribute, name: string) -> bool {
	for attribute in attributes {
		for elem in attribute.elems {
			ident, is_ident := elem.derived.(^odin_ast.Ident)
			if is_ident && ident.name == name {
				return true
			}
		}
	}
	return false
}
