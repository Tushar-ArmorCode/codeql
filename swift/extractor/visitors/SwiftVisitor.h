#pragma once

#include "swift/extractor/infra/SwiftDispatcher.h"
#include "swift/extractor/visitors/DeclVisitor.h"
#include "swift/extractor/visitors/ExprVisitor.h"
#include "swift/extractor/visitors/StmtVisitor.h"
#include "swift/extractor/visitors/TypeVisitor.h"
#include "swift/extractor/visitors/PatternVisitor.h"

namespace codeql {

class SwiftVisitor : private SwiftDispatcher {
 public:
  using SwiftDispatcher::SwiftDispatcher;

  template <typename T>
  void extract(T* entity) {
    fetchLabel(entity);
  }

 private:
  void visit(swift::Decl* decl) override { declVisitor.visit(decl); }
  void visit(swift::Stmt* stmt) override { stmtVisitor.visit(stmt); }
  void visit(swift::StmtCondition* cond) override { stmtVisitor.visitStmtCondition(cond); }
  void visit(swift::CaseLabelItem* item) override { stmtVisitor.visitCaseLabelItem(item); }
  void visit(swift::Expr* expr) override { exprVisitor.visit(expr); }
  void visit(swift::Pattern* pattern) override { patternVisitor.visit(pattern); }
  void visit(swift::TypeBase* type) override { typeVisitor.visit(type); }
  void visit(swift::TypeRepr* typeRepr, swift::Type type) override {
    typeVisitor.visit(*typeRepr, type);
  }

  DeclVisitor declVisitor{*this};
  ExprVisitor exprVisitor{*this};
  StmtVisitor stmtVisitor{*this};
  TypeVisitor typeVisitor{*this};
  PatternVisitor patternVisitor{*this};
};

}  // namespace codeql
