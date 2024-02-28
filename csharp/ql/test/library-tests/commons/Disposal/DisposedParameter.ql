import dotnet
import semmle.code.csharp.commons.Disposal

from DotNet::Callable c, DotNet::Parameter param, int p
where
  mayBeDisposed(param) and
  param = c.getParameter(p) and
  c.getDeclaringType().hasFullyQualifiedName("", "Disposal")
select c.toStringWithTypes(), p
