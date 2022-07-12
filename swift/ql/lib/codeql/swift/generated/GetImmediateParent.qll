// generated by codegen/codegen.py
import codeql.swift.elements.Element

/**
 * Gets any of the "immediate" children of `e`. "Immediate" means not taking into account node resolution: for example
 * if the AST child is the first of a series of conversions that would normally be hidden away, this will select the
 * next conversion down the hidden AST tree instead of the corresponding fully uncoverted node at the bottom.
 * Outside this module this file is mainly intended to be used to test uniqueness of parents.
 */
cached
Element getAnImmediateChild(Element e) {
  // why does this look more complicated than it should?
  // * `exists` and the `x` variable are there to reuse the same generation done in classes (where `x` is used to hide
  //   nodes via resolution)
  // * none() simplifies generation, as we can append `or ...` without a special case for the first item
  exists(Element x |
    result = x and
    (
      none()
      or
      callable_params(e, _, x)
      or
      callable_bodies(e, x)
      or
      abstract_storage_decl_accessor_decls(e, _, x)
      or
      enum_case_decl_elements(e, _, x)
      or
      enum_element_decl_params(e, _, x)
      or
      pattern_binding_decl_inits(e, _, x)
      or
      pattern_binding_decl_patterns(e, _, x)
      or
      subscript_decl_params(e, _, x)
      or
      top_level_code_decls(e, x)
      or
      any_try_exprs(e, x)
      or
      apply_exprs(e, x)
      or
      apply_expr_arguments(e, _, x)
      or
      arguments(e, _, x)
      or
      array_expr_elements(e, _, x)
      or
      assign_exprs(e, x, _)
      or
      assign_exprs(e, _, x)
      or
      bind_optional_exprs(e, x)
      or
      capture_list_expr_binding_decls(e, _, x)
      or
      capture_list_exprs(e, x)
      or
      dictionary_expr_elements(e, _, x)
      or
      dot_syntax_base_ignored_exprs(e, x, _)
      or
      dot_syntax_base_ignored_exprs(e, _, x)
      or
      dynamic_type_exprs(e, x)
      or
      enum_is_case_exprs(e, x, _)
      or
      enum_is_case_exprs(e, _, x)
      or
      explicit_cast_exprs(e, x)
      or
      force_value_exprs(e, x)
      or
      identity_exprs(e, x)
      or
      if_exprs(e, x, _, _)
      or
      if_exprs(e, _, x, _)
      or
      if_exprs(e, _, _, x)
      or
      implicit_conversion_exprs(e, x)
      or
      in_out_exprs(e, x)
      or
      interpolated_string_literal_expr_interpolation_count_exprs(e, x)
      or
      interpolated_string_literal_expr_literal_capacity_exprs(e, x)
      or
      interpolated_string_literal_expr_appending_exprs(e, x)
      or
      key_path_application_exprs(e, x, _)
      or
      key_path_application_exprs(e, _, x)
      or
      key_path_expr_roots(e, x)
      or
      key_path_expr_parsed_paths(e, x)
      or
      lazy_initializer_exprs(e, x)
      or
      lookup_exprs(e, x)
      or
      make_temporarily_escapable_exprs(e, x, _, _)
      or
      make_temporarily_escapable_exprs(e, _, x, _)
      or
      make_temporarily_escapable_exprs(e, _, _, x)
      or
      obj_c_selector_exprs(e, x, _)
      or
      one_way_exprs(e, x)
      or
      open_existential_exprs(e, x, _, _)
      or
      open_existential_exprs(e, _, x, _)
      or
      open_existential_exprs(e, _, _, x)
      or
      optional_evaluation_exprs(e, x)
      or
      rebind_self_in_constructor_exprs(e, x, _)
      or
      rebind_self_in_constructor_exprs(e, _, x)
      or
      self_apply_exprs(e, x)
      or
      sequence_expr_elements(e, _, x)
      or
      subscript_expr_arguments(e, _, x)
      or
      tap_expr_sub_exprs(e, x)
      or
      tap_exprs(e, x, _)
      or
      tuple_element_exprs(e, x, _)
      or
      tuple_expr_elements(e, _, x)
      or
      type_expr_type_reprs(e, x)
      or
      unresolved_dot_exprs(e, x, _)
      or
      vararg_expansion_exprs(e, x)
      or
      binding_patterns(e, x)
      or
      enum_element_pattern_sub_patterns(e, x)
      or
      expr_patterns(e, x)
      or
      is_pattern_cast_type_reprs(e, x)
      or
      is_pattern_sub_patterns(e, x)
      or
      optional_some_patterns(e, x)
      or
      paren_patterns(e, x)
      or
      tuple_pattern_elements(e, _, x)
      or
      typed_patterns(e, x)
      or
      typed_pattern_type_reprs(e, x)
      or
      brace_stmt_elements(e, _, x)
      or
      case_label_items(e, x)
      or
      case_label_item_guards(e, x)
      or
      case_stmts(e, x)
      or
      case_stmt_labels(e, _, x)
      or
      condition_element_booleans(e, x)
      or
      condition_element_patterns(e, x)
      or
      condition_element_initializers(e, x)
      or
      defer_stmts(e, x)
      or
      do_catch_stmts(e, x)
      or
      do_catch_stmt_catches(e, _, x)
      or
      do_stmts(e, x)
      or
      for_each_stmts(e, x, _, _)
      or
      for_each_stmts(e, _, x, _)
      or
      for_each_stmt_wheres(e, x)
      or
      for_each_stmts(e, _, _, x)
      or
      guard_stmts(e, x)
      or
      if_stmts(e, x)
      or
      if_stmt_elses(e, x)
      or
      labeled_conditional_stmts(e, x)
      or
      repeat_while_stmts(e, x, _)
      or
      repeat_while_stmts(e, _, x)
      or
      return_stmt_results(e, x)
      or
      stmt_condition_elements(e, _, x)
      or
      switch_stmts(e, x)
      or
      switch_stmt_cases(e, _, x)
      or
      throw_stmts(e, x)
      or
      while_stmts(e, x)
      or
      yield_stmt_results(e, _, x)
    )
  )
}

/**
 * Gets the "immediate" parent of `e`. "Immediate" means not taking into account node resolution: for example
 * if `e` has conversions, `getImmediateParent(e)` will give the bottom conversion in the hidden AST.
 */
Element getImmediateParent(Element e) {
  // `unique` is used here to tell the optimizer that there is in fact only one result
  // this is tested by the `library-tests/parent/no_double_parents.ql` test
  result = unique(Element x | e = getAnImmediateChild(x) | x)
}
