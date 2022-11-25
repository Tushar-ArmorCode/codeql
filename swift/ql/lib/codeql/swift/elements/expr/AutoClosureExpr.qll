private import codeql.swift.generated.expr.AutoClosureExpr
private import codeql.swift.elements.stmt.ReturnStmt
private import codeql.swift.elements.expr.Expr

/**
 * A Swift autoclosure expression, that is, a closure automatically generated
 * around an argument when the parameter has the `@autoclosure` attribute. For
 * example, there is an `AutoClosureExpr` around the value `0` in:
 * ```
 * func myFunction(_ expr: @autoclosure () -> Int) {
 *   ...
 * }
 *
 * myFunction(0)
 * ```
 */
class AutoClosureExpr extends Generated::AutoClosureExpr {
  /**
   * Gets the implicit return statement generated by this autoclosure expression.
   */
  ReturnStmt getReturn() { result = unique( | | this.getBody().getAnElement()) }

  /**
   * Gets the expression returned by this autoclosure expression.
   */
  Expr getExpr() { result = this.getReturn().getResult() }

  override string toString() { result = this.getBody().toString() }
}
