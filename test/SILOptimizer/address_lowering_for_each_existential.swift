// RUN: %target-swift-frontend -sil-verify-all -enable-sil-opaque-values -parse-as-library -emit-sil -Onone %s | %FileCheck %s

// Regression test: `for v in c` over an existential collection (`any
// Collection`) under opaque values used to fail SIL verification with
// "inconsistent stack states entering basic block." AddressLowering allocates
// storage for the loop's per-iteration `Optional<Element>` phi value in the
// function entry; without the loop-aware guard in `sinkProjections`, the
// alloc would be sunk into the loop header, leaving the matching
// `dealloc_stack` behind in the loop exit and re-allocating every iteration.
//
// CHECK-LABEL: sil @${{.*}}testForEachAnyCollection{{.*}} :
// Phi storage for the per-iteration Optional<Any> is allocated up-front in
// the entry block, BEFORE the loop body — not in the loop header.
// CHECK:       bb0(%0 : $*any Collection):
// CHECK:         [[PHI_STK:%[^,]+]] = alloc_stack [lexical] $Optional<Any>
// CHECK:         alloc_stack $any IteratorProtocol
// CHECK:         br [[HEADER:bb[0-9]+]]
//
// Loop header allocates the per-iteration apply @out slot for iterator.next().
// CHECK:       [[HEADER]]:
// CHECK:         [[NEXT_STK:%[^,]+]] = alloc_stack $Optional<{{.*}}>
// CHECK:         switch_enum_addr [[NEXT_STK]], case #Optional.some!enumelt:
//
// Back-edge block: dealloc the per-iteration slot then loop back to header.
// The phi storage [[PHI_STK]] is NOT deallocated on this path.
// CHECK:       [[BACK_EDGE:bb[0-9]+]]:
// CHECK:         dealloc_stack [[NEXT_STK]]
// CHECK-NEXT:    br [[HEADER]]
//
// Loop exit block: dealloc both per-iteration slot and phi storage, return.
// CHECK:       [[EXIT:bb[0-9]+]]:
// CHECK:         dealloc_stack [[NEXT_STK]]
// CHECK:         dealloc_stack [[PHI_STK]]
// CHECK-NEXT:    return
// CHECK-LABEL: } // end sil function '${{.*}}testForEachAnyCollection{{.*}}'
public func testForEachAnyCollection(_ c: any Collection) {
  for v in c {
    _ = v
  }
}
