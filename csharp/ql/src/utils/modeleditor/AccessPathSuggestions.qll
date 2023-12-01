/** Provides classes and predicates related to handling access path suggestions for the VS Code extension. */

private import csharp
private import semmle.code.csharp.commons.Collections as Collections
private import FrameworkModeEndpointsQuery
private import ModelEditor

/** A collection type */
abstract private class CollectionType extends RefType {
  abstract Type getElementType();
}

private class ArrayCollectionType extends CollectionType, ArrayType {
  override Type getElementType() { result = this.(ArrayType).getElementType() }
}

private class GenericCollectionType extends CollectionType, ConstructedType,
  Collections::CollectionType
{
  GenericCollectionType() {
    // Only include collections with a single type argument, which we expect to be lists.
    count(int i | exists(this.getTypeArgument(i))) = 1
  }

  override Type getElementType() { result = this.getTypeArgument(0) }
}

private predicate nestedPathBase(
  Endpoint endpoint, Element element, string value, string details, string defType,
  boolean isInputOnly, boolean isOutputOnly
) {
  endpoint.getReturnType() = element and
  isInputOnly = false and
  isOutputOnly = true and
  value = "ReturnValue" and
  details = element.toString() and
  defType = "return"
  or
  exists(Parameter parameter |
    endpoint.getAParameter() = parameter and parameter.getType() = element
  |
    value = "Argument[" + parameter.getPosition() + "]" and
    details = parameter.getType().toString() + " " + parameter.getName() and
    isInputOnly = false and
    isOutputOnly = false and
    defType = "parameter"
  )
  or
  endpoint.getDeclaringType() = element and
  isInputOnly = false and
  isOutputOnly = false and
  value = "Argument[this]" and
  details = element.toString() and
  defType = "class"
}

private predicate nestedPathRec(
  Endpoint endpoint, Element element, string value, string details, string defType,
  boolean isInputOnly, boolean isOutputOnly, int pathLength
) {
  pathLength < 8 and
  (
    nestedPathBase(endpoint, element, value, details, defType, isInputOnly, isOutputOnly) and
    pathLength = 1
    or
    exists(
      Type prevType, string prevValue, string prevDetails, string prevDefType,
      boolean prevIsInputOnly, boolean prevIsOutputOnly, int prevPathLength
    |
      nestedPathRec(endpoint, prevType, prevValue, prevDetails, prevDefType, prevIsInputOnly,
        prevIsOutputOnly, prevPathLength) and
      pathLength = prevPathLength + 1
    |
      element = prevType.(CollectionType).getElementType() and
      value = prevValue + ".Element" and
      details = element.toString() and
      isInputOnly = prevIsInputOnly and
      isOutputOnly = prevIsOutputOnly and
      defType = "array"
      or
      element = prevType.(CollectionType).getElementType() and
      (value = prevValue + ".WithoutElement" or value = prevValue + ".WithElement") and
      details = element.toString() and
      isInputOnly = true and
      isOutputOnly = prevIsOutputOnly and
      defType = "array"
      or
      element = prevType.(RefType).getAField() and
      not element.(Field).isStatic() and
      value = prevValue + ".Field[" + element.(Field).getFullyQualifiedName() + "]" and
      details = element.(Field).getType().toString() + " " + element.(Field).getName() and
      isInputOnly = false and
      isOutputOnly = false and
      defType = "field"
      or
      element = prevType.(RefType).getAProperty() and
      not element.(Property).isStatic() and
      value = prevValue + ".Property[" + element.(Property).getFullyQualifiedName() + "]" and
      details = element.(Property).getType().toString() + " " + element.(Property).getName() and
      isInputOnly = false and
      isOutputOnly = false and
      defType = "property"
    )
  )
}

predicate nestedPath(
  Endpoint endpoint, Element element, string value, string details, string defType,
  boolean isInputOnly, boolean isOutputOnly
) {
  nestedPathRec(endpoint, element, value, details, defType, isInputOnly, isOutputOnly, _)
}
