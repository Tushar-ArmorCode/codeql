private import ruby
private import codeql.ruby.frameworks.Archive

query predicate rubyZipFileOpens(RubyZip::RubyZipFileOpen f) { any() }

query predicate rubyZipFileNew(RubyZip::RubyZipFileNew f) { any() }
