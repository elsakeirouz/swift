// RUN: %target-swift-frontend -enable-sil-opaque-values -emit-sil %s

// Regression test for the `'self' is borrowed and cannot be consumed`
// diagnostic firing on `borrowing` accessors and methods of copyable structs
// when compiling with opaque values.
//
// SILGen emits a +1 owned form for `borrowing` self of `@noImplicitCopy`
// loadable copyable types so the move-only object checker can analyze the
// mark on owned storage:
//
//     %wrap = copyable_to_moveonlywrapper [guaranteed] %self
//     %copy = copy_value %wrap
//     %mark = mark_unresolved_non_copyable_value [no_consume_or_assign] %copy
//     ... uses ...
//     destroy_value %mark
//
// Under opaque values, AddressLowering recognizes this `copy_value → mark
// [no_consume_or_assign]` pattern with a guaranteed source and projects both
// onto the source's storage, erasing the artificial `destroy_value` cleanup.
// Without that projection the destroy_value would either lower to a
// `destroy_addr` of borrowed storage (illegal SIL) or survive as a consuming
// boundary use of the +1 owned mark and trip the move-only address checker's
// `[no_consume_or_assign]` diagnostic.
//
// This test passes if the program compiles without tripping that diagnostic.

struct Loaner<T> {
  let value: T
  var property: T { borrowing get { value } }
  borrowing func method() -> T { value }
}
