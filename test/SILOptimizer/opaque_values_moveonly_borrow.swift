// RUN: %target-swift-frontend -enable-sil-opaque-values -emit-sil %s

// Regression test for an `isInitialized()` assertion failure in the
// MoveOnlyChecker when compiling with opaque values.
//
// Passing a stored `~Copyable` value as a `borrowing` argument produces, under
// opaque values, a value-form copy that AddressLowering reifies into
// `alloc_stack` + `copy_addr [init]` immediately before a
// `mark_unresolved_non_copyable_value [no_consume_or_assign]`. The move-only
// address checker could not establish def-initialization for that mark and
// hit the assertion.
//
// This test passes if the program compiles without tripping the assertion.

struct NC: ~Copyable {
  var x: Int = 0
}

final class Holder {
  var inner: NC
  init(i: consuming NC) { self.inner = i }
}

func borrowMe<T: ~Copyable>(_ n: borrowing T) {}

func caller(_ h: Holder) {
  borrowMe(h.inner)
}
