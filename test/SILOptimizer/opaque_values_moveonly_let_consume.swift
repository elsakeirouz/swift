// RUN: %target-swift-frontend -enable-sil-opaque-values -emit-sil %s

// Regression test for an `(isInitialized())` assertion failure in the
// FieldSensitivePrunedLiveness machinery used by MoveOnlyAddressChecker
// when compiling with opaque values.
//
// SILGen emits the `consume q` operator on a `let` binding of a generic
// `~Copyable` type as an SSA chain:
//
//     %loaded = load [copy] %q_storage
//     %moved  = move_value [allows_diagnostics] %loaded
//     %mark   = mark_unresolved_non_copyable_value [consumable_and_assignable]
//                                                  %moved
//
// Under opaque values, AddressLowering materializes this into a fresh
// `alloc_stack` initialized by `copy_addr [init]` and then marked. The
// resulting mark sits on a slot whose initialization writes to the slot
// itself rather than through the mark, so MoveOnlyAddressChecker's
// `GatherUsesVisitor` (walking transitively from the mark) can't reach
// the init via the use-chain.
//
// This test passes if the program compiles without tripping that
// assertion.

struct U<T>: ~Copyable {
  var x: T
}

func test<T>(_ a: T) {
  let q = U<T>(x: a)
  _ = consume q
}
