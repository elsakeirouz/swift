// RUN: %target-swift-emit-silgen -Xllvm -sil-print-types %s | %FileCheck %s --check-prefix=ADDRESSES
// RUN: %target-swift-emit-silgen -Xllvm -sil-print-types -enable-sil-opaque-values %s | %FileCheck %s --check-prefix=OPAQUE

// Converting a function that takes `T?` to one that takes `T` goes through a
// reabstraction thunk that wraps its argument in `Optional.some`.
//
// With opaque values `Optional<T>` of a generic `T` is an address-only value,
// so the `enum` instruction owns its payload, and the thunk has to copy its
// guaranteed argument first. Forwarding the guaranteed argument itself used to
// fail the ownership verifier, as an address-only `enum` is owned.

// With lowered addresses, the thunk builds the optional in a buffer.
// ADDRESSES-LABEL: sil shared [transparent] [serialized] [reabstraction_thunk] [ossa] @$sxSgSiIegnd_xSiIegnd_lTR : $@convention(thin) <T> (@in_guaranteed T, @guaranteed @callee_guaranteed (@in_guaranteed Optional<T>) -> Int) -> Int {
// ADDRESSES:       bb0([[ARG:%.*]] : $*T, [[FN:%.*]] : @guaranteed $@callee_guaranteed (@in_guaranteed Optional<T>) -> Int):
// ADDRESSES:         [[OPT:%.*]] = alloc_stack $Optional<T>
// ADDRESSES:         [[PAYLOAD:%.*]] = init_enum_data_addr [[OPT]] : $*Optional<T>, #Optional.some!enumelt
// ADDRESSES:         inject_enum_addr [[OPT]] : $*Optional<T>, #Optional.some!enumelt
// ADDRESSES:         apply [[FN]]([[OPT]])
// ADDRESSES:         destroy_addr [[OPT]] : $*Optional<T>

// With opaque values, the thunk copies its guaranteed argument, wraps the owned
// copy in the `enum`, and borrows the optional for the call.
// OPAQUE-LABEL: sil shared [transparent] [serialized] [reabstraction_thunk] [ossa] [opaque] @$sxSgSiIegnd_xSiIegnd_lTR : $@convention(thin) <T> (@in_guaranteed T, @guaranteed @callee_guaranteed (@in_guaranteed Optional<T>) -> Int) -> Int {
// OPAQUE:       bb0([[ARG:%.*]] : @guaranteed $T, [[FN:%.*]] : @guaranteed $@callee_guaranteed (@in_guaranteed Optional<T>) -> Int):
// OPAQUE:         [[COPY:%.*]] = copy_value [[ARG]] : $T
// OPAQUE:         [[OPT:%.*]] = enum $Optional<T>, #Optional.some!enumelt, [[COPY]] : $T
// OPAQUE:         [[BORROW:%.*]] = begin_borrow [[OPT]] : $Optional<T>
// OPAQUE:         apply [[FN]]([[BORROW]])
// OPAQUE:         end_borrow [[BORROW]] : $Optional<T>
// OPAQUE:         destroy_value [[OPT]] : $Optional<T>
func foo<T>(_ fn: @escaping (T?) -> Int) {
  let _: (T) -> Int = fn
}
