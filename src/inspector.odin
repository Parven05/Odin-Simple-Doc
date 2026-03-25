package doc

import "core:fmt"
import odin_ast "core:odin/ast"
import "core:odin/parser"
import "core:odin/tokenizer"

main :: proc() {

	// init parse
	pkg, ok := parser.collect_package("test")
	if !ok {
		fmt.println("Error collecting package")
		return
	}

	// parse package
	ok = parser.parse_package(pkg)
	if !ok {
		fmt.println("Error parsing package")
		return
	}

	// walk in AST
	for __, file in pkg.files {
		walk_ast(file)
	}

	// tokenizer
	for _, file in pkg.files {
		fmt.printf("Tokenizing File: %s\n", file.fullpath)

		t: tokenizer.Tokenizer
		tokenizer.init(&t, file.src, file.fullpath)

		for {
			token := tokenizer.scan(&t)
			if token.kind == .EOF do break

			if token.kind == .Proc {
				fmt.printf("Found 'proc' at line %d, col %d\n", token.pos.line, token.pos.column)
			}
		}

	}
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
		for name_expr, i in derived.names {

			ident, ok := name_expr.derived_expr.(^odin_ast.Ident)
			if !ok do continue
			name := ident.name

			if i >= len(derived.values) do continue
			value := derived.values[i]

			proc_lit, is_proc := value.derived_expr.(^odin_ast.Proc_Lit)
			if !is_proc do continue

			fmt.printf("Proc: %s\n", name)
			if proc_lit.type == nil do continue

			fmt.printf("  calling convention: %v\n", proc_lit.type.calling_convention)
			fmt.printf("  is generic: %v\n", proc_lit.type.generic)
			fmt.printf("  diverging: %v\n", proc_lit.type.diverging)

			// attributes
			for attr in derived.attributes {
				for element in attr.elems {
					attr_ident, ok := element.derived_expr.(^odin_ast.Ident)
					if ok {
						fmt.printf("  attribute: %s\n", attr_ident.name)
					}
				}
			}

			// parameters
			if proc_lit.type.params != nil {
				for field in proc_lit.type.params.list {
					// param name
					for param_name in field.names {
						pident, ok := param_name.derived_expr.(^odin_ast.Ident)
						if ok {
							fmt.printf("  param name: %s\n", pident.name)
						}
					}
					// param type
					if field.type != nil {
						ptype, ok := field.type.derived_expr.(^odin_ast.Ident)
						if ok {
							fmt.printf("  param type: %s\n", ptype.name)
						}
					}
					// param default value
					if field.default_value != nil {
						def, ok := field.default_value.derived_expr.(^odin_ast.Basic_Lit)
						if ok {
							fmt.printf("  param default: %s\n", def.tok.text)
						}
					}
				}
			}

			// results
			if proc_lit.type.results != nil {
				for field in proc_lit.type.results.list {
					// result name
					for result_name in field.names {
						rident, ok := result_name.derived_expr.(^odin_ast.Ident)
						if ok {
							fmt.printf("  return name: %s\n", rident.name)
						}
					}
					// result type
					if field.type != nil {
						rtype, ok := field.type.derived_expr.(^odin_ast.Ident)
						if ok {
							fmt.printf("  return type: %s\n", rtype.name)
						}
					}
				}
			}

			fmt.printf("  has body: %v\n", proc_lit.body != nil)
			fmt.printf("  inlining: %v\n", proc_lit.inlining)
			if proc_lit.where_clauses != nil {
				fmt.printf("  has where clauses: true\n")
			}
		}
	}
}
