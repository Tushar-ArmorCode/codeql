// generated by codegen/codegen.py
private import codeql.swift.generated.Synth
private import codeql.swift.generated.Raw
import codeql.swift.elements.Element
import codeql.swift.elements.Location

module Generated {
  class Locatable extends Synth::TLocatable, Element {
    /**
     * Gets the location associated with this element in the code, if it exists.
     *
     * This includes nodes from the "hidden" AST. It can be overridden in subclasses to change the
     * behavior of both the `Immediate` and non-`Immediate` versions.
     */
    Location getImmediateLocation() {
      result =
        Synth::convertLocationFromRaw(Synth::convertLocatableToRaw(this)
              .(Raw::Locatable)
              .getLocation())
    }

    /**
     * Gets the location associated with this element in the code, if it exists.
     */
    final Location getLocation() { result = this.getImmediateLocation().resolve() }

    /**
     * Holds if `getLocation()` exists.
     */
    final predicate hasLocation() { exists(this.getLocation()) }
  }
}
