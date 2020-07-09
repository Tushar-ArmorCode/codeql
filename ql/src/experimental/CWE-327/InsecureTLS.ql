/**
 * @name Insecure TLS configuration
 * @description If an application supports insecure TLS versions or ciphers, it may be vulnerable to
 *              man-in-the-middle and other attacks.
 * @kind path-problem
 * @problem.severity warning
 * @id go/insecure-tls
 * @tags security
 *       external/cwe/cwe-327
 */

import go
import DataFlow::PathGraph
import semmle.go.security.InsecureFeatureFlag::InsecureFeatureFlag

/**
 * Check whether the file where the node is located is a test file.
 */
predicate isTestFile(DataFlow::Node node) {
  // Exclude results in test files:
  exists(File file | file = node.getRoot().getFile() |
    file instanceof TestFile or file.getPackageName() = "tests"
  )
}

predicate isInsecureTlsVersion(int val, string name, string fieldName) {
  (fieldName = "MinVersion" or fieldName = "MaxVersion") and
  // tls.VersionSSL30
  (
    val = 768 and name = "VersionSSL30"
    or
    // tls.VersionTLS10
    val = 769 and name = "VersionTLS10"
    or
    // tls.VersionTLS11
    val = 770 and name = "VersionTLS11"
    or
    // Zero indicates the lowest available version setting for MinVersion,
    // or the highest available version setting for MaxVersion.
    val = 0 and name = "" and fieldName = "MinVersion"
  )
}

/**
 * Flow of TLS versions into a `tls.Config` struct, to the `MinVersion` and `MaxVersion` fields.
 */
class TlsVersionFlowConfig extends TaintTracking::Configuration {
  TlsVersionFlowConfig() { this = "TlsVersionFlowConfig" }

  predicate isSource(DataFlow::Node source, int val) { val = source.getIntValue() }

  predicate isSink(DataFlow::Node sink, Field fld, DataFlow::Node base, Write fieldWrite) {
    fld.hasQualifiedName("crypto/tls", "Config", ["MinVersion", "MaxVersion"]) and
    fieldWrite = fld.getAWrite() and
    fieldWrite.writesField(base, fld, sink)
  }

  override predicate isSource(DataFlow::Node source) { isSource(source, _) }

  override predicate isSink(DataFlow::Node sink) { isSink(sink, _, _, _) }
}

/**
 * Holds if a secure TLS version may reach `sink`, which writes to `base`.`fld`
 */
predicate secureTlsVersionFlowsToSink(DataFlow::PathNode sink, Field fld, DataFlow::Node base) {
  exists(TlsVersionFlowConfig secureCfg, DataFlow::PathNode source, int version |
    secureCfg.hasFlowPath(source, sink) and
    secureCfg.isSink(sink.getNode(), fld, base, _) and
    secureCfg.isSource(source.getNode(), version) and
    not isInsecureTlsVersion(version, _, fld.getName())
  )
}

/**
 * Holds if a secure TLS version may reach `baseEntity`.`fld`
 */
predicate secureTlsVersionFlowsToEntity(ValueEntity baseEntity, Field fld) {
  exists(DataFlow::PathNode sink, DataFlow::Node base |
    secureTlsVersionFlowsToSink(sink, fld, base) and
    base.(DataFlow::ReadNode).reads(baseEntity)
  )
}

/**
 * Holds if a secure TLS version may reach `base`.`fld`
 */
predicate secureTlsVersionFlowsToField(DataFlow::Node base, Field fld) {
  secureTlsVersionFlowsToSink(_, fld, base)
  or
  exists(ValueEntity baseEntity |
    base.(DataFlow::ReadNode).reads(baseEntity) and
    secureTlsVersionFlowsToEntity(baseEntity, fld)
  )
}

/**
 * Find insecure TLS versions.
 */
predicate checkTlsVersions(
  DataFlow::PathNode source, DataFlow::PathNode sink, string message, DataFlow::Node base
) {
  exists(TlsVersionFlowConfig cfg, int version, Field fld |
    cfg.hasFlowPath(source, sink) and
    cfg.isSource(source.getNode(), version) and
    cfg.isSink(sink.getNode(), fld, base, _) and
    isInsecureTlsVersion(version, _, fld.getName()) and
    // Exclude cases where a secure TLS version can also flow to the same
    // sink, or to different sinks that refer to the same base and field,
    // which suggests a configurable security mode. baseAlias is used because
    // isSink will return both implicit dereferences and the expression
    // accessed.
    not exists(DataFlow::Node baseAlias |
      cfg.isSink(sink.getNode(), fld, baseAlias, _) and
      secureTlsVersionFlowsToField(baseAlias, fld)
    )
  |
    version = 0 and
    message = "Using lowest TLS version for " + fld + "."
    or
    version != 0 and
    exists(string name | isInsecureTlsVersion(version, name, _) |
      message = "Using insecure TLS version " + name + " for " + fld + "."
    )
  )
}

/**
 * Flow of unsecure TLS cipher suites into a `tls.Config` struct,
 * to the `CipherSuites` field.
 */
class TlsInsecureCipherSuitesFlowConfig extends TaintTracking::Configuration {
  TlsInsecureCipherSuitesFlowConfig() { this = "TlsInsecureCipherSuitesFlowConfig" }

  predicate isSourceValueEntity(DataFlow::Node source, string suiteName) {
    exists(DataFlow::ValueEntity val |
      val.hasQualifiedName("crypto/tls", suiteName) and
      suiteName =
        ["TLS_RSA_WITH_RC4_128_SHA", "TLS_RSA_WITH_AES_128_CBC_SHA256",
            "TLS_ECDHE_ECDSA_WITH_RC4_128_SHA", "TLS_ECDHE_RSA_WITH_RC4_128_SHA",
            "TLS_ECDHE_ECDSA_WITH_AES_128_CBC_SHA256", "TLS_ECDHE_RSA_WITH_AES_128_CBC_SHA256"]
    |
      source = val.getARead()
    )
  }

  predicate isSourceInsecureCipherSuites(DataFlow::Node source) {
    exists(Function insecureCipherSuites |
      insecureCipherSuites.hasQualifiedName("crypto/tls", "InsecureCipherSuites")
    |
      source = insecureCipherSuites.getACall().getResult()
    )
  }

  override predicate isSource(DataFlow::Node source) {
    // TODO: source can also be result of tls.InsecureCipherSuites()[0].ID
    isSourceInsecureCipherSuites(source)
    or
    isSourceValueEntity(source, _)
  }

  override predicate isSink(DataFlow::Node sink) {
    exists(DataFlow::Field fld | fld.hasQualifiedName("crypto/tls", "Config", "CipherSuites") |
      sink = fld.getAWrite().getRhs()
    )
  }

  /**
   * Declare sinks as out-sanitizers in order to avoid producing superfluous paths where a cipher
   * is written to CipherSuites, then the list is further extended with either safe or tainted
   * suites.
   */
  override predicate isSanitizerOut(DataFlow::Node node) {
    super.isSanitizerOut(node) or isSink(node)
  }
}

/**
 * Find insecure TLS cipher suites.
 */
predicate checkTlsInsecureCipherSuites(
  DataFlow::PathNode source, DataFlow::PathNode sink, string message
) {
  exists(TlsInsecureCipherSuitesFlowConfig cfg | cfg.hasFlowPath(source, sink) |
    exists(string name | cfg.isSourceValueEntity(source.getNode(), name) |
      message = "Use of an insecure cipher suite: " + name + "."
    )
    or
    cfg.isSourceInsecureCipherSuites(source.getNode()) and
    message = "Use of an insecure cipher suite from InsecureCipherSuites()."
  )
}

from DataFlow::PathNode source, DataFlow::PathNode sink, string message
where
  (
    checkTlsVersions(source, sink, message, _) or
    checkTlsInsecureCipherSuites(source, sink, message)
  ) and
  // Exclude sinks guarded by a feature flag
  not getAFeatureFlagCheck().dominatesNode(sink.getNode().asInstruction()) and
  // Exclude results in functions whose name documents the insecurity
  not exists(FuncDef fn | fn = sink.getNode().asInstruction().getRoot() |
    isFeatureFlagName(fn.getEnclosingFunction*().getName())
  ) and
  // Exclude results in test code:
  not isTestFile(sink.getNode())
select sink.getNode(), source, sink, message
