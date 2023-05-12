// generated by codegen/codegen.py
private import codeql.swift.generated.Synth
private import codeql.swift.generated.Raw
import codeql.swift.elements.stmt.Stmt

module Generated {
  class ContinueStmt extends Synth::TContinueStmt, Stmt {
    override string getAPrimaryQlClass() { result = "ContinueStmt" }

    /**
     * Gets the target name of this continue statement, if it exists.
     */
    string getTargetName() {
      result = Synth::convertContinueStmtToRaw(this).(Raw::ContinueStmt).getTargetName()
    }

    /**
     * Holds if `getTargetName()` exists.
     */
    final predicate hasTargetName() { exists(this.getTargetName()) }

    /**
     * Gets the target of this continue statement, if it exists.
     *
     * This includes nodes from the "hidden" AST. It can be overridden in subclasses to change the
     * behavior of both the `Immediate` and non-`Immediate` versions.
     */
    Stmt getImmediateTarget() {
      result =
        Synth::convertStmtFromRaw(Synth::convertContinueStmtToRaw(this)
              .(Raw::ContinueStmt)
              .getTarget())
    }

    /**
     * Gets the target of this continue statement, if it exists.
     */
    final Stmt getTarget() { result = this.getImmediateTarget().resolve() }

    /**
     * Holds if `getTarget()` exists.
     */
    final predicate hasTarget() { exists(this.getTarget()) }
  }
}
