// generated by codegen/codegen.py
import codeql.swift.elements.type.Type
import codeql.swift.elements.decl.ValueDecl

class TypeDeclBase extends @type_decl, ValueDecl {
  string getName() { type_decls(this, result) }

  Type getBaseType(int index) {
    exists(Type x |
      type_decl_base_types(this, index, x) and
      result = x.resolve()
    )
  }

  Type getABaseType() { result = getBaseType(_) }

  int getNumberOfBaseTypes() { result = count(getABaseType()) }
}
