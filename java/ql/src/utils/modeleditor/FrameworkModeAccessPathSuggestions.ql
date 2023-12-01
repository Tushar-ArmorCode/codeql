/**
 * @name Fetch suggestions for access paths of input and output parameters of a method (framework mode)
 * @description A list of access paths for input and output parameters of a method. Excludes test and generated code.
 * @kind table
 * @id java/utils/modeleditor/framework-mode-access-path-suggestions
 * @tags modeleditor access-path-suggestions framework-mode
 */

private import java
private import AccessPathSuggestions
private import FrameworkModeEndpointsQuery
private import ModelEditor

predicate suggestions(
  string packageName, string typeName, string methodName, string methodParameters, string value,
  string details, string defType, boolean isInputOnly, boolean isOutputOnly
) {
  exists(PublicEndpointFromSource endpoint, Element element |
    nestedPath(endpoint, element, value, details, defType, isInputOnly, isOutputOnly)
  |
    packageName = endpoint.getPackageName() and
    typeName = endpoint.getTypeName() and
    methodName = endpoint.getName() and
    methodParameters = endpoint.getParameterTypes()
  )
}

predicate inputSuggestions(
  string packageName, string typeName, string methodName, string methodParameters, string value,
  string details, string defType
) {
  suggestions(packageName, typeName, methodName, methodParameters, value, details, defType, _, false)
}

predicate outputSuggestions(
  string packageName, string typeName, string methodName, string methodParameters, string value,
  string details, string defType
) {
  suggestions(packageName, typeName, methodName, methodParameters, value, details, defType, false, _)
}

query predicate input = inputSuggestions/7;

query predicate output = outputSuggestions/7;
