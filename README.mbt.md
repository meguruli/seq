## Seq — Immutable sequence based on Finger Tree (MoonBit)

An immutable sequence library powered by Finger Trees. It provides a strict `Seq[A]` and a lazy spine `LSeq[A]`, balancing ergonomics with solid asymptotic guarantees.

- Module: `meguruli/seq`
- Version: `0.1.0`
- License: Apache-2.0

## 🚀 Key Features

- **Immutable sequences**: strict `Seq[A]` and lazy `LSeq[A]` (built on `CAIMEOX/lazy`)
- **Construction & concatenation**: `empty/singleton/cons/snoc/append/from_list/to_list`
- **Query & splitting**: `null/length/lookup/index/split_at/uncons/unsnoc`
- **Positional updates**: `insert_at/delete_at/update/adjust`
- **Transform & combine**: `map/map_with_index/filter/reverse/concat/concat_map`
- **Scan & unfold**: `scanl/scanr/unfoldl/unfoldr`
- **Zipping**: `zip/zip_with/unzip`
- **Predicate-based splits**: `take_while/drop_while/take_while_right/drop_while_right/span/break_seq/span_right/break_right`
- **Logarithmic index/split/append** via measured Finger Tree; others are linear

Note: `to_list` in this project is defined via a left fold with front insertion (as used in tests), so the visible order is reversed (“stack-like”).

## 📥 Installation

```bash
moon add meguruli/seq@0.1.0
```

## 🔨 Quick Start

```moonbit
///|
test "quick start" (_t : @test.T) {
  // Strict sequence
  let s : Seq[Int] = Seq::from_list(@list.from_array([1, 2, 3]))
  let u = Seq::append(Seq::singleton(0), s)
  inspect(Seq::to_list(u), content="@list.from_array([3, 2, 1, 0])")

  // Logarithmic index and split
  inspect(Seq::lookup(u, 1), content="Some(1)")
  let (l, r) = Seq::split_at(u, 2)
  inspect(Seq::to_list(l), content="@list.from_array([1, 0])")
  inspect(Seq::to_list(r), content="@list.from_array([3, 2])")
}
```

## 💤 Lazy Spine (LSeq) Quick Start

```moonbit
///|
test "quick start lseq" (_t : @test.T) {
  let s : LSeq[Int] = LSeq::from_list(@list.from_array([1, 2, 3]))
  let u = LSeq::append(LSeq::singleton(0), s)
  inspect(LSeq::to_list(u), content="@list.from_array([3, 2, 1, 0])")
  inspect(LSeq::lookup(u, 1), content="Some(1)")
  let (l, r) = LSeq::split_at(u, 2)
  inspect(LSeq::to_list(l), content="@list.from_array([1, 0])")
  inspect(LSeq::to_list(r), content="@list.from_array([3, 2])")
}
```

## 🎯 Everyday Operations

```moonbit
///|
test "everyday ops" (_t : @test.T) {
  let s = Seq::from_list(@list.from_array([1, 2, 3, 4]))

  // Update & transform
  let s1 = Seq::update(s, 1, 20)
  let s2 = Seq::insert_at(s1, 2, 99)
  let s3 = Seq::delete_at(s2, 3)
  let s4 = Seq::map(s3, fn(x) { x * 2 })
  inspect(Seq::to_list(s4), content="@list.from_array([8, 198, 40, 2])")

  // Predicate-based splits (left/right variants)
  let twl = Seq::take_while_left(s, fn(x) { x < 4 })
  let dwr = Seq::drop_while_right(s, fn(x) { x > 3 })
  inspect(Seq::to_list(twl), content="@list.from_array([3, 2, 1])")
  inspect(Seq::to_list(dwr), content="@list.from_array([3, 2, 1])")

  // Concatenate & zip
  let z = Seq::zip(
    Seq::from_list(@list.from_array([1, 2, 3])),
    Seq::from_list(@list.from_array([10, 20, 30])),
  )
  inspect(
    Seq::to_list(z),
    content="@list.from_array([(3, 30), (2, 20), (1, 10)])",
  )
}
```

## 📚 API Overview (selected)

- **Construct/base**: `empty`, `singleton`, `cons`, `snoc`, `append`, `from_list`, `to_list`, `null`, `length`
- **Query/split**: `lookup`, `index`, `split_at`, `uncons`, `unsnoc`, `take`, `drop`, `take_right`, `drop_right`
- **Edits**: `insert_at`, `delete_at`, `update`, `adjust`
- **Transform/combine**: `map`, `map_with_index`, `filter`, `reverse`, `concat`, `concat_map`
- **Scan/unfold**: `scanl`, `scanr`, `unfoldl`, `unfoldr`
- **Pairs**: `zip`, `zip_with`, `unzip`
- **Predicates**: `take_while`, `drop_while`, `take_while_right`, `drop_while_right`, `span`, `break_seq`, `span_right`, `break_right`

`LSeq` mirrors `Seq` APIs with lazy evaluation over the underlying finger tree, suitable for amortized composition and deferred computation.

## 📈 Complexity Characteristics (current implementation)

| Operation | Time | Notes |
|-----------|------|-------|
| `cons` / `snoc` | amortized O(1) | finger digits growth |
| `append` | O(log min(n,m)) | via middle layer join |
| `lookup` / `index` | O(log n) | measured descent |
| `split_at` | O(log n) | first-pivot split |
| `insert_at` | O(log n) | `split_at` + append |
| `to_list` / `map` / `filter` | O(n) | fold-and-rebuild |
| `take` / `drop` (strict) | O(n) | implemented via folds |
| `update` / `delete_at` | O(n) | sequential rebuild |

Note: `LSeq` defers most costs until forced; overall big-O is the same order as strict.

## 🧪 Tests

20 test cases cover construction, concatenation, index/split, transforms, scans, and lazy sequences.

```bash
moon test
# When you intentionally change snapshots:
moon test --update
```

## 🧰 Build & Maintenance

```bash
# Update interface and format
moon info && moon fmt

# Static checks
moon check
```

## 🏗️ Project Structure

```
seq/
├── seq.mbt                # Core implementation (Finger Tree + Seq/LSeq APIs)
├── seq_test.mbt           # Tests
├── moon.mod.json          # Module info (name/version/license/readme)
├── moon.pkg.json          # Package deps (imports CAIMEOX/lazy)
├── pkg.generated.mbti     # Interface file (generated by moon info)
├── README.mbt.md          # This MoonBit-flavored README (Chinese)
├── README.md              # English README (for GitHub)
└── LICENSE                # Apache-2.0 license
```

## 📜 License

Apache-2.0. See `LICENSE` for details.

## 🔗 Reference

- Haskell containers `Data.Sequence`: [`Data.Sequence` docs](https://hackage-content.haskell.org/package/containers-0.8/docs/Data-Sequence.html)
