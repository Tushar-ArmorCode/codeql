private import codeql.ruby.AST
private import codeql.ruby.Concepts
private import codeql.ruby.DataFlow
private import codeql.ruby.ApiGraphs

/**
 * The `Kernel` module is included by the `Object` class, so its methods are available
 * in every Ruby object. In addition, its module methods can be called by
 * providing a specific receiver as in `Kernel.exit`.
 */
class KernelMethodCall extends MethodCall {
  KernelMethodCall() {
    this = API::getTopLevelMember("Kernel").getAMethodCall(_).asExpr().getExpr()
    or
    // we assume that if there's no obvious target for this method call
    // and the method name matches a Kernel method, then it is a Kernel method call.
    // TODO: ApiGraphs should ideally handle this case
    not exists(this.(Call).getATarget()) and
    (
      this.getReceiver() instanceof Self and isPrivateKernelMethod(this.getMethodName())
      or
      isPublicKernelMethod(this.getMethodName())
    )
  }
}

/**
 * Public methods in the `Kernel` module. These can be invoked on any object via the usual dot syntax.
 * ```ruby
 * arr = []
 * arr.send("push", 5) # => [5]
 * ```
 */
private predicate isPublicKernelMethod(string method) {
  method in ["class", "clone", "frozen?", "tap", "then", "yield_self", "send"]
}

/**
 * Private methods in the `Kernel` module.
 * These can be be invoked on `self`, on `Kernel`, or using a low-level primitive like `send` or `instance_eval`.
 * ```ruby
 * puts "hello world"
 * Kernel.puts "hello world"
 * 5.instance_eval { puts "hello world" }
 * 5.send("puts", "hello world")
 * ```
 */
private predicate isPrivateKernelMethod(string method) {
  method in [
      "Array", "Complex", "Float", "Hash", "Integer", "Rational", "String", "__callee__", "__dir__",
      "__method__", "`", "abort", "at_exit", "autoload", "autoload?", "binding", "block_given?",
      "callcc", "caller", "caller_locations", "catch", "chomp", "chop", "eval", "exec", "exit",
      "exit!", "fail", "fork", "format", "gets", "global_variables", "gsub", "iterator?", "lambda",
      "load", "local_variables", "loop", "open", "p", "pp", "print", "printf", "proc", "putc",
      "puts", "raise", "rand", "readline", "readlines", "require", "require_relative", "select",
      "set_trace_func", "sleep", "spawn", "sprintf", "srand", "sub", "syscall", "system", "test",
      "throw", "trace_var", "trap", "untrace_var", "warn"
    ]
}

/**
 * A system command executed via subshell literal syntax.
 * E.g.
 * ```ruby
 * `cat foo.txt`
 * %x(cat foo.txt)
 * %x[cat foo.txt]
 * %x{cat foo.txt}
 * %x/cat foo.txt/
 * ```
 */
class SubshellLiteralExecution extends SystemCommandExecution::Range {
  SubshellLiteral literal;

  SubshellLiteralExecution() { this.asExpr().getExpr() = literal }

  override DataFlow::Node getAnArgument() { result.asExpr().getExpr() = literal.getComponent(_) }

  override predicate isShellInterpreted(DataFlow::Node arg) { arg = getAnArgument() }
}

/**
 * A system command executed via shell heredoc syntax.
 * E.g.
 * ```ruby
 * <<`EOF`
 * cat foo.text
 * EOF
 * ```
 */
class SubshellHeredocExecution extends SystemCommandExecution::Range {
  HereDoc heredoc;

  SubshellHeredocExecution() { this.asExpr().getExpr() = heredoc and heredoc.isSubShell() }

  override DataFlow::Node getAnArgument() { result.asExpr().getExpr() = heredoc.getComponent(_) }

  override predicate isShellInterpreted(DataFlow::Node arg) { arg = getAnArgument() }
}

/**
 * A system command executed via the `Kernel.system` method.
 * `Kernel.system` accepts three argument forms:
 * - A single string. If it contains no shell meta characters, keywords or
 *   builtins, it is executed directly in a subprocess.
 *   Otherwise, it is executed in a subshell.
 *   ```ruby
 *   system("cat foo.txt | tail")
 *   ```
 * - A command and one or more arguments.
 *   The command is executed in a subprocess.
 *   ```ruby
 *   system("cat", "foo.txt")
 *   ```
 * - An array containing the command name and argv[0], followed by zero or more arguments.
 *   The command is executed in a subprocess.
 *   ```ruby
 *   system(["cat", "cat"], "foo.txt")
 *   ```
 * In addition, `Kernel.system` accepts an optional environment hash as the
 * first argument and an optional options hash as the last argument.
 * We don't yet distinguish between these arguments and the command arguments.
 * ```ruby
 * system({"FOO" => "BAR"}, "cat foo.txt | tail", {unsetenv_others: true})
 * ```
 * Ruby documentation: https://docs.ruby-lang.org/en/3.0.0/Kernel.html#method-i-system
 */
class KernelSystemCall extends SystemCommandExecution::Range {
  KernelMethodCall methodCall;

  KernelSystemCall() {
    methodCall.getMethodName() = "system" and
    this.asExpr().getExpr() = methodCall
  }

  override DataFlow::Node getAnArgument() { result.asExpr().getExpr() = methodCall.getAnArgument() }

  override predicate isShellInterpreted(DataFlow::Node arg) {
    // Kernel.system invokes a subshell if you provide a single string as argument
    methodCall.getNumberOfArguments() = 1 and arg.asExpr().getExpr() = methodCall.getAnArgument()
  }
}

/**
 * A system command executed via the `Kernel.exec` method.
 * `Kernel.exec` takes the same argument forms as `Kernel.system`. See `KernelSystemCall` for details.
 * Ruby documentation: https://docs.ruby-lang.org/en/3.0.0/Kernel.html#method-i-exec
 */
class KernelExecCall extends SystemCommandExecution::Range {
  KernelMethodCall methodCall;

  KernelExecCall() {
    methodCall.getMethodName() = "exec" and
    this.asExpr().getExpr() = methodCall
  }

  override DataFlow::Node getAnArgument() { result.asExpr().getExpr() = methodCall.getAnArgument() }

  override predicate isShellInterpreted(DataFlow::Node arg) {
    // Kernel.exec invokes a subshell if you provide a single string as argument
    methodCall.getNumberOfArguments() = 1 and arg.asExpr().getExpr() = methodCall.getAnArgument()
  }
}

/**
 * A system command executed via the `Kernel.spawn` method.
 * `Kernel.spawn` takes the same argument forms as `Kernel.system`.
 * See `KernelSystemCall` for details.
 * Ruby documentation: https://docs.ruby-lang.org/en/3.0.0/Kernel.html#method-i-spawn
 * TODO: document and handle the env and option arguments.
 * ```
 * spawn([env,] command... [,options]) -> pid
 * ```
 */
class KernelSpawnCall extends SystemCommandExecution::Range {
  KernelMethodCall methodCall;

  KernelSpawnCall() {
    methodCall.getMethodName() = "spawn" and
    this.asExpr().getExpr() = methodCall
  }

  override DataFlow::Node getAnArgument() { result.asExpr().getExpr() = methodCall.getAnArgument() }

  override predicate isShellInterpreted(DataFlow::Node arg) {
    // Kernel.spawn invokes a subshell if you provide a single string as argument
    methodCall.getNumberOfArguments() = 1 and arg.asExpr().getExpr() = methodCall.getAnArgument()
  }
}

/**
 * A system command executed via one of the `Open3` methods.
 * These methods take the same argument forms as `Kernel.system`.
 * See `KernelSystemCall` for details.
 */
class Open3Call extends SystemCommandExecution::Range {
  MethodCall methodCall;

  Open3Call() {
    this.asExpr().getExpr() = methodCall and
    this =
      API::getTopLevelMember("Open3")
          .getAMethodCall(["popen3", "popen2", "popen2e", "capture3", "capture2", "capture2e"])
  }

  override DataFlow::Node getAnArgument() { result.asExpr().getExpr() = methodCall.getAnArgument() }

  override predicate isShellInterpreted(DataFlow::Node arg) {
    // These Open3 methods invoke a subshell if you provide a single string as argument
    methodCall.getNumberOfArguments() = 1 and arg.asExpr().getExpr() = methodCall.getAnArgument()
  }
}

/**
 * A pipeline of system commands constructed via one of the `Open3` methods.
 * These methods accept a variable argument list of commands.
 * Commands can be in any form supported by `Kernel.system`. See `KernelSystemCall` for details.
 * ```ruby
 * Open3.pipeline("cat foo.txt", "tail")
 * Open3.pipeline(["cat", "foo.txt"], "tail")
 * Open3.pipeline([{}, "cat", "foo.txt"], "tail")
 * Open3.pipeline([["cat", "cat"], "foo.txt"], "tail")
 */
class Open3PipelineCall extends SystemCommandExecution::Range {
  MethodCall methodCall;

  Open3PipelineCall() {
    this.asExpr().getExpr() = methodCall and
    this =
      API::getTopLevelMember("Open3")
          .getAMethodCall(["pipeline_rw", "pipeline_r", "pipeline_w", "pipeline_start", "pipeline"])
  }

  override DataFlow::Node getAnArgument() { result.asExpr().getExpr() = methodCall.getAnArgument() }

  override predicate isShellInterpreted(DataFlow::Node arg) {
    // A command in the pipeline is executed in a subshell if it is given as a single string argument.
    arg.asExpr().getExpr() instanceof StringlikeLiteral and
    arg.asExpr().getExpr() = methodCall.getAnArgument()
  }
}

/**
 * A call to `Kernel.eval`, which executes its argument as Ruby code.
 * ```ruby
 * a = 1
 * Kernel.eval("a = 2")
 * a # => 2
 * ```
 */
class EvalCallCodeExecution extends CodeExecution::Range {
  KernelMethodCall methodCall;

  EvalCallCodeExecution() {
    this.asExpr().getExpr() = methodCall and methodCall.getMethodName() = "eval"
  }

  override DataFlow::Node getCode() { result.asExpr().getExpr() = methodCall.getAnArgument() }
}

/**
 * A call to `Kernel#send`, which executes its arguments as a Ruby method call.
 * ```ruby
 * arr = []
 * arr.send("push", 1)
 * arr # => [1]
 * ```
 */
class SendCallCodeExecution extends CodeExecution::Range {
  KernelMethodCall methodCall;

  SendCallCodeExecution() {
    this.asExpr().getExpr() = methodCall and methodCall.getMethodName() = "send"
  }

  override DataFlow::Node getCode() { result.asExpr().getExpr() = methodCall.getAnArgument() }
}
