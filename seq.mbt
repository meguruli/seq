///|
/// 基于 Finger Tree 的不可变序列 `Seq[A]`
/// - 实现核心构造：empty/singleton/cons/snoc/append/from_list/to_list
/// - 实现基础查询与变换：null/length/lookup/index/take/drop/split_at
///   以及 insert_at/delete_at/update/map/map_with_index/filter/reverse
///
/// 说明：
/// - 这里移植了 finger_tree.mbt 中的核心 FingerTree 结构与操作（不可跨文件调用）
/// - 为 Digit/Node/Tree/FingerTree 节点加入 size（测度）字段，并在构造操作中维护，
///   使 `index/split_at` 可达到对数级复杂度（其余 API 维持原有行为与语义）。
using @list {type List}

///|
using @lazy {type Lazy}

///|

///|

///|
priv enum Node[A] {
  Node2(Int, A, A)
  Node3(Int, A, A, A)
}

///|
priv enum Digit[A] {
  One(A)
  Two(A, A)
  Three(A, A, A)
  Four(A, A, A, A)
}

///|
priv enum Tree[A] {
  Single(Int, A)
  SingleNode(Int, Node[Tree[A]])
  //              ^^^^^^^
  //              Self
  Deep(Int, Digit[A])
  DeepNode(Int, Digit[Node[Tree[A]]])
  //                  ^^^^^^^
  //                  Self
}

///|
priv enum FingerTree[A] {
  Empty
  Single(Tree[A])
  // legacy shape kept for folding; size carried via helpers below
  Deep(Tree[A], FingerTree[A], Tree[A])
}

///|
fn[A] Node::measure(self : Node[A]) -> Int {
  match self {
    Node2(sz, _, _) => sz
    Node3(sz, _, _, _) => sz
  }
}

///|
fn[A] Tree::measure(self : Tree[A]) -> Int {
  match self {
    Single(sz, _) => sz
    SingleNode(sz, _) => sz
    Deep(sz, _) => sz
    DeepNode(sz, _) => sz
  }
}

///|
fn[A] Tree::single(a : A) -> Tree[A] {
  Single(1, a)
}

///|
fn[A] Digit::size_as_elems(self : Digit[A]) -> Int {
  match self {
    One(_) => 1
    Two(_, _) => 2
    Three(_, _, _) => 3
    Four(_, _, _, _) => 4
  }
}

///|
fn[A] Digit::sum_by(self : Digit[A], f : (A) -> Int) -> Int {
  match self {
    One(a) => f(a)
    Two(a, b) => f(a) + f(b)
    Three(a, b, c) => f(a) + f(b) + f(c)
    Four(a, b, c, d) => f(a) + f(b) + f(c) + f(d)
  }
}

///|
fn[A] Tree::deep(d : Digit[A]) -> Tree[A] {
  Deep(Digit::size_as_elems(d), d)
}

///|
fn[A] Node::node2_tree(a : Tree[A], b : Tree[A]) -> Node[Tree[A]] {
  Node2(Tree::measure(a) + Tree::measure(b), a, b)
}

///|
fn[A] Node::node3_tree(a : Tree[A], b : Tree[A], c : Tree[A]) -> Node[Tree[A]] {
  Node3(Tree::measure(a) + Tree::measure(b) + Tree::measure(c), a, b, c)
}

///|
fn[A] Tree::single_node(n : Node[Tree[A]]) -> Tree[A] {
  SingleNode(Node::measure(n), n)
}

///|
fn[A] Tree::deep_node(d : Digit[Node[Tree[A]]]) -> Tree[A] {
  DeepNode(Digit::sum_by(d, Node::measure), d)
}

///|
fn[A, B] Node::fold_left(self : Node[A], acc : B, f : (B, A) -> B) -> B {
  match self {
    Node2(_, a, b) => f(f(acc, a), b)
    Node3(_, a, b, c) => f(f(f(acc, a), b), c)
  }
}

///|
fn[A, B] Digit::fold_left(self : Digit[A], acc : B, f : (B, A) -> B) -> B {
  match self {
    One(a) => f(acc, a)
    Two(a, b) => f(f(acc, a), b)
    Three(a, b, c) => f(f(f(acc, a), b), c)
    Four(a, b, c, d) => f(f(f(f(acc, a), b), c), d)
  }
}

///|
fn[A, B] Tree::fold_left(self : Tree[A], acc : B, f : (B, A) -> B) -> B {
  match self {
    Deep(_, d) => Digit::fold_left(d, acc, f)
    DeepNode(_, dn) => {
      fn fold_tree(acc, x) {
        Tree::fold_left(x, acc, f)
      }

      fn fold_node(acc, x) {
        Node::fold_left(x, acc, fold_tree)
      }

      Digit::fold_left(dn, acc, fold_node)
    }
    Single(_, a) => f(acc, a)
    SingleNode(_, n) =>
      Node::fold_left(n, acc, (acc, x) => Tree::fold_left(x, acc, f))
  }
}

///|
fn[A, B] FingerTree::fold_left(
  self : FingerTree[A],
  acc : B,
  f : (B, A) -> B,
) -> B {
  match self {
    Empty => acc
    Single(t) => Tree::fold_left(t, acc, f)
    Deep(pr, m, sf) => {
      let acc1 = Tree::fold_left(pr, acc, f)
      let acc2 = FingerTree::fold_left(m, acc1, f)
      Tree::fold_left(sf, acc2, f)
    }
  }
}

///|
fn[A] Digit::lookup(self : Digit[A], i : Int) -> A? {
  if i < 0 {
    return None
  }
  match self {
    One(a) => if i == 0 { Some(a) } else { None }
    Two(a, b) => if i == 0 { Some(a) } else if i == 1 { Some(b) } else { None }
    Three(a, b, c) =>
      if i == 0 {
        Some(a)
      } else if i == 1 {
        Some(b)
      } else if i == 2 {
        Some(c)
      } else {
        None
      }
    Four(a, b, c, d) =>
      if i == 0 {
        Some(a)
      } else if i == 1 {
        Some(b)
      } else if i == 2 {
        Some(c)
      } else if i == 3 {
        Some(d)
      } else {
        None
      }
  }
}

///|
fn[A] Node::lookup(self : Node[Tree[A]], i : Int) -> A? {
  if i < 0 {
    return None
  }
  match self {
    Node2(_, a, b) => {
      let sa = Tree::measure(a)
      if i < sa {
        Tree::lookup(a, i)
      } else {
        Tree::lookup(b, i - sa)
      }
    }
    Node3(_, a, b, c) => {
      let sa = Tree::measure(a)
      if i < sa {
        return Tree::lookup(a, i)
      }
      let ib = i - sa
      let sb = Tree::measure(b)
      if ib < sb {
        Tree::lookup(b, ib)
      } else {
        Tree::lookup(c, ib - sb)
      }
    }
  }
}

///|
fn[A] Tree::lookup(self : Tree[A], i : Int) -> A? {
  if i < 0 {
    return None
  }
  match self {
    Single(sz, a) => if i == 0 && sz == 1 { Some(a) } else { None }
    SingleNode(_, n) => Node::lookup(n, i)
    Deep(_, d) => Digit::lookup(d, i)
    DeepNode(_, dn) =>
      match dn {
        One(n) => Node::lookup(n, i)
        Two(n1, n2) => {
          let s1 = Node::measure(n1)
          if i < s1 {
            Node::lookup(n1, i)
          } else {
            Node::lookup(n2, i - s1)
          }
        }
        Three(n1, n2, n3) => {
          let s1 = Node::measure(n1)
          if i < s1 {
            return Node::lookup(n1, i)
          }
          let i2 = i - s1
          let s2 = Node::measure(n2)
          if i2 < s2 {
            Node::lookup(n2, i2)
          } else {
            Node::lookup(n3, i2 - s2)
          }
        }
        Four(n1, n2, n3, n4) => {
          let s1 = Node::measure(n1)
          if i < s1 {
            return Node::lookup(n1, i)
          }
          let i2 = i - s1
          let s2 = Node::measure(n2)
          if i2 < s2 {
            return Node::lookup(n2, i2)
          }
          let i3 = i2 - s2
          let s3 = Node::measure(n3)
          if i3 < s3 {
            Node::lookup(n3, i3)
          } else {
            Node::lookup(n4, i3 - s3)
          }
        }
      }
  }
}

///|
fn[A] FingerTree::measure(self : FingerTree[A]) -> Int {
  match self {
    Empty => 0
    Single(t) => Tree::measure(t)
    Deep(pr, m, sf) =>
      Tree::measure(pr) + FingerTree::measure(m) + Tree::measure(sf)
  }
}

///|
fn[A] FingerTree::lookup(self : FingerTree[A], i : Int) -> A? {
  if i < 0 {
    return None
  }
  match self {
    Empty => None
    Single(t) => Tree::lookup(t, i)
    Deep(pr, m, sf) => {
      let sp = Tree::measure(pr)
      if i < sp {
        return Tree::lookup(pr, i)
      }
      let i2 = i - sp
      let sm = FingerTree::measure(m)
      if i2 < sm {
        FingerTree::lookup(m, i2)
      } else {
        Tree::lookup(sf, i2 - sm)
      }
    }
  }
}

///|
fn[A] Tree::to_ft_unit(t : Tree[A]) -> FingerTree[A] {
  // Precondition: t is Single(_) or SingleNode(_)
  FingerTree::Single(t)
}

///|
fn[A] Digit::to_ft_elems(d : Digit[A]) -> FingerTree[A] {
  match d {
    One(a) => FingerTree::cons(a, FingerTree::Empty)
    Two(a, b) => FingerTree::snoc(FingerTree::cons(a, FingerTree::Empty), b)
    Three(a, b, c) => {
      let ft = FingerTree::cons(a, FingerTree::Empty)
      let ft = FingerTree::snoc(ft, b)
      FingerTree::snoc(ft, c)
    }
    Four(a, b, c, d) => {
      let ft = FingerTree::cons(a, FingerTree::Empty)
      let ft = FingerTree::snoc(ft, b)
      let ft = FingerTree::snoc(ft, c)
      FingerTree::snoc(ft, d)
    }
  }
}

///|
fn[A] Digit::split_elems(
  d : Digit[A],
  i : Int,
) -> (FingerTree[A], FingerTree[A]) {
  let n = Digit::size_as_elems(d)
  if i <= 0 {
    return (FingerTree::Empty, Digit::to_ft_elems(d))
  }
  if i >= n {
    return (Digit::to_ft_elems(d), FingerTree::Empty)
  }
  match d {
    One(a) =>
      // i == 0 already handled; i >= 1 handled above
      (FingerTree::cons(a, FingerTree::Empty), FingerTree::Empty)
    Two(a, b) =>
      if i == 1 {
        (
          FingerTree::cons(a, FingerTree::Empty),
          FingerTree::cons(b, FingerTree::Empty),
        )
      } else {
        (Digit::to_ft_elems(d), FingerTree::Empty)
      }
    Three(a, b, c) =>
      if i == 1 {
        (FingerTree::cons(a, FingerTree::Empty), Digit::to_ft_elems(Two(b, c)))
      } else {
        (
          // i == 2
          Digit::to_ft_elems(Two(a, b)),
          FingerTree::cons(c, FingerTree::Empty),
        )
      }
    Four(a, b, c, d0) =>
      if i == 1 {
        (
          FingerTree::cons(a, FingerTree::Empty),
          Digit::to_ft_elems(Three(b, c, d0)),
        )
      } else if i == 2 {
        (Digit::to_ft_elems(Two(a, b)), Digit::to_ft_elems(Two(c, d0)))
      } else {
        (
          Digit::to_ft_elems(Three(a, b, c)),
          FingerTree::cons(d0, FingerTree::Empty),
        )
      }
  }
}

///|
fn[A] Digit::to_ft_nodes(d : Digit[Node[Tree[A]]]) -> FingerTree[A] {
  match d {
    One(n) => FingerTree::snoc_tree(FingerTree::Empty, Tree::single_node(n))
    Two(n1, n2) => {
      let ft = FingerTree::snoc_tree(FingerTree::Empty, Tree::single_node(n1))
      FingerTree::snoc_tree(ft, Tree::single_node(n2))
    }
    Three(n1, n2, n3) => {
      let ft = FingerTree::snoc_tree(FingerTree::Empty, Tree::single_node(n1))
      let ft = FingerTree::snoc_tree(ft, Tree::single_node(n2))
      FingerTree::snoc_tree(ft, Tree::single_node(n3))
    }
    Four(n1, n2, n3, n4) => {
      let ft = FingerTree::snoc_tree(FingerTree::Empty, Tree::single_node(n1))
      let ft = FingerTree::snoc_tree(ft, Tree::single_node(n2))
      let ft = FingerTree::snoc_tree(ft, Tree::single_node(n3))
      FingerTree::snoc_tree(ft, Tree::single_node(n4))
    }
  }
}

///|
fn[A] Node::to_ft(self : Node[Tree[A]]) -> FingerTree[A] {
  match self {
    Node2(_, a, b) => {
      let ft = FingerTree::snoc_tree(FingerTree::Empty, a)
      FingerTree::snoc_tree(ft, b)
    }
    Node3(_, a, b, c) => {
      let ft = FingerTree::snoc_tree(FingerTree::Empty, a)
      let ft = FingerTree::snoc_tree(ft, b)
      FingerTree::snoc_tree(ft, c)
    }
  }
}

///|
fn[A] Node::split(
  self : Node[Tree[A]],
  i : Int,
) -> (FingerTree[A], FingerTree[A]) {
  if i <= 0 {
    return (FingerTree::Empty, Node::to_ft(self))
  }
  match self {
    Node2(_, a, b) => {
      let sa = Tree::measure(a)
      if i < sa {
        let (la, ra) = Tree::split(a, i)
        (la, FingerTree::concat(ra, Tree::to_ft_for_concat(b)))
      } else if i == sa {
        (Tree::to_ft_for_concat(a), Tree::to_ft_for_concat(b))
      } else {
        let (lb, rb) = Tree::split(b, i - sa)
        (FingerTree::concat(Tree::to_ft_for_concat(a), lb), rb)
      }
    }
    Node3(_, a, b, c) => {
      let sa = Tree::measure(a)
      if i < sa {
        let (la, ra) = Tree::split(a, i)
        (
          la,
          FingerTree::concat(
            ra,
            FingerTree::concat(
              Tree::to_ft_for_concat(b),
              Tree::to_ft_for_concat(c),
            ),
          ),
        )
      } else if i == sa {
        (
          Tree::to_ft_for_concat(a),
          FingerTree::concat(
            Tree::to_ft_for_concat(b),
            Tree::to_ft_for_concat(c),
          ),
        )
      } else {
        let i2 = i - sa
        let sb = Tree::measure(b)
        if i2 < sb {
          let (lb, rb) = Tree::split(b, i2)
          (
            FingerTree::concat(Tree::to_ft_for_concat(a), lb),
            FingerTree::concat(rb, Tree::to_ft_for_concat(c)),
          )
        } else if i2 == sb {
          (
            FingerTree::concat(
              Tree::to_ft_for_concat(a),
              Tree::to_ft_for_concat(b),
            ),
            Tree::to_ft_for_concat(c),
          )
        } else {
          let (lc, rc) = Tree::split(c, i2 - sb)
          (
            FingerTree::concat(
              FingerTree::concat(
                Tree::to_ft_for_concat(a),
                Tree::to_ft_for_concat(b),
              ),
              lc,
            ),
            rc,
          )
        }
      }
    }
  }
}

///|
fn[A] Digit::split_nodes(
  d : Digit[Node[Tree[A]]],
  i : Int,
) -> (FingerTree[A], FingerTree[A]) {
  if i <= 0 {
    return (FingerTree::Empty, Digit::to_ft_nodes(d))
  }
  match d {
    One(n1) => {
      let s1 = Node::measure(n1)
      if i >= s1 {
        (Digit::to_ft_nodes(d), FingerTree::Empty)
      } else {
        Node::split(n1, i)
      }
    }
    Two(n1, n2) => {
      let s1 = Node::measure(n1)
      if i < s1 {
        let (l1, r1) = Node::split(n1, i)
        (l1, FingerTree::concat(r1, Tree::to_ft_unit(Tree::single_node(n2))))
      } else if i == s1 {
        (
          Tree::to_ft_unit(Tree::single_node(n1)),
          Tree::to_ft_unit(Tree::single_node(n2)),
        )
      } else {
        let (l2, r2) = Node::split(n2, i - s1)
        (FingerTree::concat(Tree::to_ft_unit(Tree::single_node(n1)), l2), r2)
      }
    }
    Three(n1, n2, n3) => {
      let s1 = Node::measure(n1)
      if i < s1 {
        let (l1, r1) = Node::split(n1, i)
        (
          l1,
          FingerTree::concat(
            r1,
            FingerTree::concat(
              Tree::to_ft_unit(Tree::single_node(n2)),
              Tree::to_ft_unit(Tree::single_node(n3)),
            ),
          ),
        )
      } else if i == s1 {
        (
          Tree::to_ft_unit(Tree::single_node(n1)),
          FingerTree::concat(
            Tree::to_ft_unit(Tree::single_node(n2)),
            Tree::to_ft_unit(Tree::single_node(n3)),
          ),
        )
      } else {
        let i2 = i - s1
        let s2 = Node::measure(n2)
        if i2 < s2 {
          let (l2, r2) = Node::split(n2, i2)
          (
            FingerTree::concat(Tree::to_ft_unit(Tree::single_node(n1)), l2),
            FingerTree::concat(r2, Tree::to_ft_unit(Tree::single_node(n3))),
          )
        } else if i2 == s2 {
          (
            FingerTree::concat(
              Tree::to_ft_unit(Tree::single_node(n1)),
              Tree::to_ft_unit(Tree::single_node(n2)),
            ),
            Tree::to_ft_unit(Tree::single_node(n3)),
          )
        } else {
          let (l3, r3) = Node::split(n3, i2 - s2)
          (
            FingerTree::concat(
              FingerTree::concat(
                Tree::to_ft_unit(Tree::single_node(n1)),
                Tree::to_ft_unit(Tree::single_node(n2)),
              ),
              l3,
            ),
            r3,
          )
        }
      }
    }
    Four(n1, n2, n3, n4) => {
      let s1 = Node::measure(n1)
      if i < s1 {
        let (l1, r1) = Node::split(n1, i)
        (
          l1,
          FingerTree::concat(
            r1,
            FingerTree::concat(
              Tree::to_ft_unit(Tree::single_node(n2)),
              FingerTree::concat(
                Tree::to_ft_unit(Tree::single_node(n3)),
                Tree::to_ft_unit(Tree::single_node(n4)),
              ),
            ),
          ),
        )
      } else if i == s1 {
        (
          Tree::to_ft_unit(Tree::single_node(n1)),
          FingerTree::concat(
            Tree::to_ft_unit(Tree::single_node(n2)),
            FingerTree::concat(
              Tree::to_ft_unit(Tree::single_node(n3)),
              Tree::to_ft_unit(Tree::single_node(n4)),
            ),
          ),
        )
      } else {
        let i2 = i - s1
        let s2 = Node::measure(n2)
        if i2 < s2 {
          let (l2, r2) = Node::split(n2, i2)
          (
            FingerTree::concat(Tree::to_ft_unit(Tree::single_node(n1)), l2),
            FingerTree::concat(
              r2,
              FingerTree::concat(
                Tree::to_ft_unit(Tree::single_node(n3)),
                Tree::to_ft_unit(Tree::single_node(n4)),
              ),
            ),
          )
        } else if i2 == s2 {
          (
            FingerTree::concat(
              Tree::to_ft_unit(Tree::single_node(n1)),
              Tree::to_ft_unit(Tree::single_node(n2)),
            ),
            FingerTree::concat(
              Tree::to_ft_unit(Tree::single_node(n3)),
              Tree::to_ft_unit(Tree::single_node(n4)),
            ),
          )
        } else {
          let i3 = i2 - s2
          let s3 = Node::measure(n3)
          if i3 < s3 {
            let (l3, r3) = Node::split(n3, i3)
            (
              FingerTree::concat(
                FingerTree::concat(
                  Tree::to_ft_unit(Tree::single_node(n1)),
                  Tree::to_ft_unit(Tree::single_node(n2)),
                ),
                l3,
              ),
              FingerTree::concat(r3, Tree::to_ft_unit(Tree::single_node(n4))),
            )
          } else if i3 == s3 {
            (
              FingerTree::concat(
                FingerTree::concat(
                  Tree::to_ft_unit(Tree::single_node(n1)),
                  Tree::to_ft_unit(Tree::single_node(n2)),
                ),
                Tree::to_ft_unit(Tree::single_node(n3)),
              ),
              Tree::to_ft_unit(Tree::single_node(n4)),
            )
          } else {
            let (l4, r4) = Node::split(n4, i3 - s3)
            (
              FingerTree::concat(
                FingerTree::concat(
                  Tree::to_ft_unit(Tree::single_node(n1)),
                  Tree::to_ft_unit(Tree::single_node(n2)),
                ),
                FingerTree::concat(Tree::to_ft_unit(Tree::single_node(n3)), l4),
              ),
              r4,
            )
          }
        }
      }
    }
  }
}

///|
fn[A] Tree::split(self : Tree[A], i : Int) -> (FingerTree[A], FingerTree[A]) {
  match self {
    Single(_, _) =>
      if i <= 0 {
        (FingerTree::Empty, FingerTree::Single(self))
      } else {
        (FingerTree::Single(self), FingerTree::Empty)
      }
    SingleNode(_, n) => Node::split(n, i)
    Deep(_, d) => Digit::split_elems(d, i)
    DeepNode(_, dn) => Digit::split_nodes(dn, i)
  }
}

///|
fn[A] Tree::to_ft_for_concat(self : Tree[A]) -> FingerTree[A] {
  match self {
    Single(_, _) | SingleNode(_, _) => FingerTree::Single(self)
    Deep(_, d) => Digit::to_ft_elems(d)
    DeepNode(_, dn) => Digit::to_ft_nodes(dn)
  }
}

///|
fn[A] FingerTree::append_right_tree(
  ft : FingerTree[A],
  tree : Tree[A],
) -> FingerTree[A] {
  let right = Tree::to_ft_for_concat(tree)
  let left_norm = FingerTree::normalize_single_deep(ft)
  FingerTree::concat(left_norm, right)
}

///|
fn[A] FingerTree::prepend_left_tree(
  tree : Tree[A],
  ft : FingerTree[A],
) -> FingerTree[A] {
  let left = Tree::to_ft_for_concat(tree)
  let right_norm = FingerTree::normalize_single_deep(ft)
  FingerTree::concat(left, right_norm)
}

///|
fn[A] FingerTree::normalize_single_deep(ft : FingerTree[A]) -> FingerTree[A] {
  match ft {
    Single(Deep(_, d)) => Digit::to_ft_elems(d)
    Single(DeepNode(_, dn)) => Digit::to_ft_nodes(dn)
    _ => ft
  }
}

///|
fn[A] FingerTree::split_at(
  self : FingerTree[A],
  i : Int,
) -> (FingerTree[A], FingerTree[A]) {
  if i <= 0 {
    return (FingerTree::Empty, self)
  }
  let total = FingerTree::measure(self)
  if i >= total {
    return (self, FingerTree::Empty)
  }
  let (ml, pivot, mr) = FingerTree::split_first_tree(self, i)
  let left_sz = FingerTree::measure(ml)
  let offset_in_pivot = i - left_sz
  let (pl, pr) = Tree::split(pivot, offset_in_pivot)
  (FingerTree::concat(ml, pl), FingerTree::concat(pr, mr))
}

///|
fn[A] FingerTree::split_first_tree(
  self : FingerTree[A],
  i : Int,
) -> (FingerTree[A], Tree[A], FingerTree[A]) {
  match self {
    Empty => abort("split_first_tree on empty")
    Single(t) => (FingerTree::Empty, t, FingerTree::Empty)
    Deep(pr, m, sf) => {
      let sp = Tree::measure(pr)
      if i < sp {
        // pivot is in prefix tree `pr`
        (FingerTree::Empty, pr, FingerTree::append_right_tree(m, sf))
      } else {
        let i2 = i - sp
        let sm = FingerTree::measure(m)
        if i2 < sm {
          let (ml0, x, mr0) = FingerTree::split_first_tree(m, i2)
          let left_part = match ml0 {
            Empty => Tree::to_ft_for_concat(pr)
            _ => {
              let (_, hd, rest) = FingerTree::split_first_tree(ml0, 0)
              FingerTree::Deep(pr, rest, hd)
            }
          }
          let right_part = match mr0 {
            Empty => Tree::to_ft_for_concat(sf)
            _ => {
              let (_, hd, rest) = FingerTree::split_first_tree(mr0, 0)
              FingerTree::Deep(hd, rest, sf)
            }
          }
          (left_part, x, right_part)
        } else {
          // pivot is in suffix tree `sf`
          (FingerTree::prepend_left_tree(pr, m), sf, FingerTree::Empty)
        }
      }
    }
  }
}

///|
fn[A] Digit::cons(a : A, digit : Digit[A]) -> Digit[A] {
  match digit {
    One(b) => Digit::Two(a, b)
    Two(b, c) => Digit::Three(a, b, c)
    Three(b, c, d) => Digit::Four(a, b, c, d)
    Four(_, _, _, _) => abort("cannot cons to a Four")
  }
}

///|
/// tree : Tree[A] refine to `Single[A] | SingleNode[A]`
fn[A] FingerTree::cons_tree(
  tree : Tree[A],
  finger_tree : FingerTree[A],
) -> FingerTree[A] {
  match (tree, finger_tree) {
    // case 1:
    (a, Empty) => FingerTree::Single(a)
    // case 2:
    (Single(_, a), Single(Single(_, b))) =>
      FingerTree::Deep(Tree::deep(One(a)), Empty, Tree::deep(One(b)))
    (SingleNode(_, a), Single(SingleNode(_, b))) =>
      FingerTree::Deep(Tree::deep_node(One(a)), Empty, Tree::deep_node(One(b)))
    // case 2 (mixed kinds): allow combining Single(elem) with Single(node)
    (Single(_, a), Single(SingleNode(_, b))) =>
      FingerTree::Deep(Tree::deep(One(a)), Empty, Tree::deep_node(One(b)))
    (SingleNode(_, a), Single(Single(_, b))) =>
      FingerTree::Deep(Tree::deep_node(One(a)), Empty, Tree::deep(One(b)))
    // case 3:
    (Single(_, a), Deep(Deep(_, Four(b, c, d, e)), m, sf)) => {
      let prefix = Tree::deep(Two(a, b))
      let node3 : Tree[A] = Tree::single_node(
        Node::node3_tree(Tree::single(c), Tree::single(d), Tree::single(e)),
      )
      let middle = FingerTree::cons_tree(node3, m)
      let suffix = sf
      FingerTree::Deep(prefix, middle, suffix)
    }
    (SingleNode(_, a), Deep(DeepNode(_, Four(b, c, d, e)), m, sf)) => {
      let prefix = Tree::deep_node(Two(a, b))
      let node3 = Tree::single_node(
        Node::node3_tree(
          Tree::single_node(c),
          Tree::single_node(d),
          Tree::single_node(e),
        ),
      )
      let middle = FingerTree::cons_tree(node3, m)
      let suffix = sf
      FingerTree::Deep(prefix, middle, suffix)
    }
    // case 4:
    (Single(_, a), Deep(Deep(_, pr), m, sf)) => {
      let prefix = Tree::deep(Digit::cons(a, pr))
      let middle = m
      let suffix = sf
      FingerTree::Deep(prefix, middle, suffix)
    }
    (SingleNode(_, a), Deep(DeepNode(_, pr), m, sf)) => {
      let prefix = Tree::deep_node(Digit::cons(a, pr))
      let middle = m
      let suffix = sf
      FingerTree::Deep(prefix, middle, suffix)
    }
    (Single(_, _), Deep(DeepNode(_, _), _, _))
    | (SingleNode(_, _), Deep(Deep(_, _), _, _)) =>
      abort("cons_tree_case3_mismatch_elem_vs_node_prefix")
    (Deep(_, _) | DeepNode(_, _), _) =>
      abort("cons_tree_invalid_left_tree_not_single")
    (
      Single(_, _)
      | SingleNode(_, _),
      Deep(Single(_, _) | SingleNode(_, _), _, _)
      | Single(Deep(_, _))
      | Single(DeepNode(_, _)),
    ) => abort("cons_tree_invalid_rhs_structure")
  }
}

///|
fn[A] FingerTree::cons(x : A, xs : FingerTree[A]) -> FingerTree[A] {
  FingerTree::cons_tree(Tree::single(x), xs)
}

///|
fn[A] Digit::snoc(digit : Digit[A], a : A) -> Digit[A] {
  match digit {
    One(b) => Digit::Two(b, a)
    Two(c, b) => Digit::Three(c, b, a)
    Three(d, c, b) => Digit::Four(d, c, b, a)
    Four(_, _, _, _) => abort("cannot snoc to a Four")
  }
}

///|
/// tree : Tree[A] refine to `Single[A] | SingleNode[A]`
fn[A] FingerTree::snoc_tree(
  finger_tree : FingerTree[A],
  tree : Tree[A],
) -> FingerTree[A] {
  match (finger_tree, tree) {
    // case 1:
    (Empty, a) => FingerTree::Single(a)
    // case 2:
    (Single(Single(_, b)), Single(_, a)) =>
      FingerTree::Deep(Tree::deep(One(b)), Empty, Tree::deep(One(a)))
    (Single(SingleNode(_, b)), SingleNode(_, a)) =>
      FingerTree::Deep(Tree::deep_node(One(b)), Empty, Tree::deep_node(One(a)))
    // case 2 (mixed kinds): allow combining Single(elem) with Single(node)
    (Single(Single(_, b)), SingleNode(_, a)) =>
      FingerTree::Deep(Tree::deep(One(b)), Empty, Tree::deep_node(One(a)))
    (Single(SingleNode(_, b)), Single(_, a)) =>
      FingerTree::Deep(Tree::deep_node(One(b)), Empty, Tree::deep(One(a)))
    // case 3:
    (Deep(pf, m, Deep(_, Four(e, d, c, b))), Single(_, a)) => {
      let prefix = pf
      let node3 : Tree[A] = Tree::single_node(
        Node::node3_tree(Tree::single(e), Tree::single(d), Tree::single(c)),
      )
      let middle = FingerTree::snoc_tree(m, node3)
      let suffix = Tree::deep(Two(b, a))
      FingerTree::Deep(prefix, middle, suffix)
    }
    (Deep(pf, m, DeepNode(_, Four(e, d, c, b))), SingleNode(_, a)) => {
      let prefix = pf
      let node3 = Tree::single_node(
        Node::node3_tree(
          Tree::single_node(e),
          Tree::single_node(d),
          Tree::single_node(c),
        ),
      )
      let middle = FingerTree::snoc_tree(m, node3)
      let suffix = Tree::deep_node(Two(b, a))
      FingerTree::Deep(prefix, middle, suffix)
    }
    // case 4:
    (Deep(pf, m, Deep(_, sf)), Single(_, a)) => {
      let prefix = pf
      let middle = m
      let suffix = Tree::deep(Digit::snoc(sf, a))
      FingerTree::Deep(prefix, middle, suffix)
    }
    (Deep(pf, m, DeepNode(_, sf)), SingleNode(_, a)) => {
      let prefix = pf
      let middle = m
      let suffix = Tree::deep_node(Digit::snoc(sf, a))
      FingerTree::Deep(prefix, middle, suffix)
    }
    (Deep(_, _, DeepNode(_, _)), Single(_, _))
    | (Deep(_, _, Deep(_, _)), SingleNode(_, _)) =>
      abort("due to the finger tree structure for case 3")
    (_, Deep(_, _) | DeepNode(_, _)) =>
      abort("due to the type refine to `Single[A] | SingleNode[A]`")
    (
      Deep(_, _, Single(_, _) | SingleNode(_, _))
      | Single(Deep(_, _))
      | Single(DeepNode(_, _)),
      Single(_, _)
      | SingleNode(_, _),
    ) =>
      abort(
        "due to the type regine to `Deep(Digit[A]) | DeepNode(Digit[Node[Tree[A]]])`",
      )
  }
}

///|
fn[A] FingerTree::snoc(xs : FingerTree[A], x : A) -> FingerTree[A] {
  FingerTree::snoc_tree(xs, Tree::single(x))
}

///|
fn[A] FingerTree::concat(
  left : FingerTree[A],
  right : FingerTree[A],
) -> FingerTree[A] {
  match (left, right) {
    (Empty, xs) => xs
    (xs, Empty) => xs
    (Single(x), xs) => FingerTree::cons_tree(x, xs)
    (xs, Single(x)) => FingerTree::snoc_tree(xs, x)
    (Deep(pr1, m1, sf1), Deep(pr2, m2, sf2)) => {
      let prefix = pr1
      let middle = FingerTree::append3_aux(
        m1,
        Tree::nodes(Tree::deep_node(One(Node::node2_tree(sf1, pr2)))),
        m2,
      )
      let suffix = sf2
      Deep(prefix, middle, suffix)
    }
  }
}

///|
fn[A] FingerTree::append3_aux(
  left : FingerTree[A],
  middle : Tree[A],
  right : FingerTree[A],
) -> FingerTree[A] {
  match (left, right) {
    (Empty, xs) => FingerTree::cons_tree(middle, xs)
    (xs, Empty) => FingerTree::snoc_tree(xs, middle)
    (Single(x), xs) =>
      FingerTree::cons_tree(x, FingerTree::cons_tree(middle, xs))
    (xs, Single(x)) =>
      FingerTree::snoc_tree(FingerTree::snoc_tree(xs, middle), x)
    (Deep(pr1, m1, sf1), Deep(pr2, m2, sf2)) => {
      let prefix = pr1
      let middle = FingerTree::append3_aux(
        m1,
        Tree::nodes(Tree::deep_node(One(Node::node3_tree(sf1, middle, pr2)))),
        m2,
      )
      let suffix = sf2
      Deep(prefix, middle, suffix)
    }
  }
}

///|
/// tree refine to `Deep(Digit[A])` or `DeepNode(Digit[Node[Tree[A]]])`
///
/// return value refine to  type refine to `Single[A]` or  `SingleNode[A]`
fn[A] Tree::nodes(tree : Tree[A]) -> Tree[A] {
  guard tree is DeepNode(_, One(node)) else { abort("impossible") }
  match node {
    Node2(_, a, b) => Tree::node_aux2(a, b)
    Node3(_, a, b, c) => Tree::node_aux3(a, b, c)
  }
}

///|
fn[A] Tree::node_aux2(left : Tree[A], right : Tree[A]) -> Tree[A] {
  fn node2(a : Tree[A], b : Tree[A]) -> Tree[A] {
    Tree::single_node(Node::node2_tree(a, b))
  }

  fn node3(a : Tree[A], b : Tree[A], c : Tree[A]) -> Tree[A] {
    Tree::single_node(Node::node3_tree(a, b, c))
  }

  match (left, right) {
    // leaf is `Single(_)`
    (Deep(_, left), Deep(_, right)) => {
      let leaf = Tree::single(_)
      match (left, right) {
        (One(a), One(b)) => node2(leaf(a), leaf(b))
        (One(a), Two(b, c)) => node3(leaf(a), leaf(b), leaf(c))
        (One(a), Three(b, c, d)) => {
          let left_node = node2(leaf(a), leaf(b))
          let right_node = node2(leaf(c), leaf(d))
          node2(left_node, right_node)
        }
        (One(a), Four(b, c, d, e)) => {
          let left_node = node2(leaf(a), leaf(b))
          let right_node = node3(leaf(c), leaf(d), leaf(e))
          node2(left_node, right_node)
        }
        (Two(a, b), One(c)) => node3(leaf(a), leaf(b), leaf(c))
        (Two(a, b), Two(c, d)) => {
          let left_node = node2(leaf(a), leaf(b))
          let right_node = node2(leaf(c), leaf(d))
          node2(left_node, right_node)
        }
        (Two(a, b), Three(c, d, e)) => {
          let left_node = node2(leaf(a), leaf(b))
          let right_node = node3(leaf(c), leaf(d), leaf(e))
          node2(left_node, right_node)
        }
        (Two(a, b), Four(c, d, e, f)) => {
          let left_node = node3(leaf(a), leaf(b), leaf(c))
          let right_node = node3(leaf(d), leaf(e), leaf(f))
          node2(left_node, right_node)
        }
        (Three(a, b, c), One(d)) => {
          let left_node = node2(leaf(a), leaf(b))
          let right_node = node2(leaf(c), leaf(d))
          node2(left_node, right_node)
        }
        (Three(a, b, c), Two(d, e)) => {
          let left_node = node2(leaf(a), leaf(b))
          let right_node = node3(leaf(c), leaf(d), leaf(e))
          node2(left_node, right_node)
        }
        (Three(a, b, c), Three(d, e, f)) => {
          let left_node = node3(leaf(a), leaf(b), leaf(c))
          let right_node = node3(leaf(d), leaf(e), leaf(f))
          node2(left_node, right_node)
        }
        (Three(a, b, c), Four(d, e, f, g)) => {
          let left_node = node3(leaf(a), leaf(b), leaf(c))
          let middle_node = node2(leaf(d), leaf(e))
          let right_node = node2(leaf(f), leaf(g))
          node3(left_node, middle_node, right_node)
        }
        (Four(a, b, c, d), One(e)) => {
          let left_node = node2(leaf(a), leaf(b))
          let right_node = node3(leaf(c), leaf(d), leaf(e))
          node2(left_node, right_node)
        }
        (Four(a, b, c, d), Two(e, f)) => {
          let left_node = node3(leaf(a), leaf(b), leaf(c))
          let right_node = node3(leaf(d), leaf(e), leaf(f))
          node2(left_node, right_node)
        }
        (Four(a, b, c, d), Three(e, f, g)) => {
          let left_node = node3(leaf(a), leaf(b), leaf(c))
          let middle_node = node2(leaf(d), leaf(e))
          let right_node = node2(leaf(f), leaf(g))
          node3(left_node, middle_node, right_node)
        }
        (Four(a, b, c, d), Four(e, f, g, h)) => {
          let left_node = node3(leaf(a), leaf(b), leaf(c))
          let middle_node = node3(leaf(d), leaf(e), leaf(f))
          let right_node = node2(leaf(g), leaf(h))
          node3(left_node, middle_node, right_node)
        }
      }
    }
    // leaf is `SingleNode(_)`
    (DeepNode(_, left), DeepNode(_, right)) => {
      let leaf = Tree::single_node(_)
      match (left, right) {
        (One(a), One(b)) => node2(leaf(a), leaf(b))
        (One(a), Two(b, c)) => node3(leaf(a), leaf(b), leaf(c))
        (One(a), Three(b, c, d)) => {
          let left_node = node2(leaf(a), leaf(b))
          let right_node = node2(leaf(c), leaf(d))
          node2(left_node, right_node)
        }
        (One(a), Four(b, c, d, e)) => {
          let left_node = node2(leaf(a), leaf(b))
          let right_node = node3(leaf(c), leaf(d), leaf(e))
          node2(left_node, right_node)
        }
        (Two(a, b), One(c)) => node3(leaf(a), leaf(b), leaf(c))
        (Two(a, b), Two(c, d)) => {
          let left_node = node2(leaf(a), leaf(b))
          let right_node = node2(leaf(c), leaf(d))
          node2(left_node, right_node)
        }
        (Two(a, b), Three(c, d, e)) => {
          let left_node = node2(leaf(a), leaf(b))
          let right_node = node3(leaf(c), leaf(d), leaf(e))
          node2(left_node, right_node)
        }
        (Two(a, b), Four(c, d, e, f)) => {
          let left_node = node3(leaf(a), leaf(b), leaf(c))
          let right_node = node3(leaf(d), leaf(e), leaf(f))
          node2(left_node, right_node)
        }
        (Three(a, b, c), One(d)) => {
          let left_node = node2(leaf(a), leaf(b))
          let right_node = node2(leaf(c), leaf(d))
          node2(left_node, right_node)
        }
        (Three(a, b, c), Two(d, e)) => {
          let left_node = node2(leaf(a), leaf(b))
          let right_node = node3(leaf(c), leaf(d), leaf(e))
          node2(left_node, right_node)
        }
        (Three(a, b, c), Three(d, e, f)) => {
          let left_node = node3(leaf(a), leaf(b), leaf(c))
          let right_node = node3(leaf(d), leaf(e), leaf(f))
          node2(left_node, right_node)
        }
        (Three(a, b, c), Four(d, e, f, g)) => {
          let left_node = node3(leaf(a), leaf(b), leaf(c))
          let middle_node = node2(leaf(d), leaf(e))
          let right_node = node2(leaf(f), leaf(g))
          node3(left_node, middle_node, right_node)
        }
        (Four(a, b, c, d), One(e)) => {
          let left_node = node2(leaf(a), leaf(b))
          let right_node = node3(leaf(c), leaf(d), leaf(e))
          node2(left_node, right_node)
        }
        (Four(a, b, c, d), Two(e, f)) => {
          let left_node = node3(leaf(a), leaf(b), leaf(c))
          let right_node = node3(leaf(d), leaf(e), leaf(f))
          node2(left_node, right_node)
        }
        (Four(a, b, c, d), Three(e, f, g)) => {
          let left_node = node3(leaf(a), leaf(b), leaf(c))
          let middle_node = node2(leaf(d), leaf(e))
          let right_node = node2(leaf(f), leaf(g))
          node3(left_node, middle_node, right_node)
        }
        (Four(a, b, c, d), Four(e, f, g, h)) => {
          let left_node = node3(leaf(a), leaf(b), leaf(c))
          let middle_node = node3(leaf(d), leaf(e), leaf(f))
          let right_node = node2(leaf(g), leaf(h))
          node3(left_node, middle_node, right_node)
        }
      }
    }
    (_, _) =>
      abort(
        "dut to type refine to `Deep(Digit[A])` or `DeepNode(Digit[Node[Tree[A]]])`",
      )
  }
}

///|
fn[A] Tree::node_aux3(
  left : Tree[A],
  middle : Tree[A],
  right : Tree[A],
) -> Tree[A] {
  fn node2(a : Tree[A], b : Tree[A]) -> Tree[A] {
    Tree::single_node(Node::node2_tree(a, b))
  }

  fn node3(a : Tree[A], b : Tree[A], c : Tree[A]) -> Tree[A] {
    Tree::single_node(Node::node3_tree(a, b, c))
  }

  match (left, middle, right) {
    // leaf is `Single(_)`
    //
    (Deep(_, left), Single(_, middle_val), Deep(_, right)) => {
      let leaf = Tree::single(_)
      match (left, right) {
        (One(a), One(b)) => node3(leaf(a), leaf(middle_val), leaf(b))
        (One(a), Two(b, c)) => {
          let left_node = node2(leaf(a), leaf(middle_val))
          let right_node = node2(leaf(b), leaf(c))
          node2(left_node, right_node)
        }
        (One(a), Three(b, c, d)) => {
          let left_node = node2(leaf(a), leaf(middle_val))
          let right_node = node3(leaf(b), leaf(c), leaf(d))
          node2(left_node, right_node)
        }
        (One(a), Four(b, c, d, e)) => {
          let left_node = node3(leaf(a), leaf(middle_val), leaf(b))
          let right_node = node3(leaf(c), leaf(d), leaf(e))
          node2(left_node, right_node)
        }
        (Two(a, b), One(c)) => {
          let left_node = node2(leaf(a), leaf(b))
          let right_node = node2(leaf(middle_val), leaf(c))
          node2(left_node, right_node)
        }
        (Two(a, b), Two(c, d)) => {
          let left_node = node2(leaf(a), leaf(b))
          let middle_node = leaf(middle_val)
          let right_node = node2(leaf(c), leaf(d))
          node3(left_node, middle_node, right_node)
        }
        (Two(a, b), Three(c, d, e)) => {
          let left_node = node3(leaf(a), leaf(b), leaf(middle_val))
          let right_node = node3(leaf(c), leaf(d), leaf(e))
          node2(left_node, right_node)
        }
        (Two(a, b), Four(c, d, e, f)) => {
          let left_node = node3(leaf(a), leaf(b), leaf(middle_val))
          let middle_node = node2(leaf(c), leaf(d))
          let right_node = node2(leaf(e), leaf(f))
          node3(left_node, middle_node, right_node)
        }
        (Three(a, b, c), One(d)) => {
          let left_node = node3(leaf(a), leaf(b), leaf(c))
          let right_node = node2(leaf(middle_val), leaf(d))
          node2(left_node, right_node)
        }
        (Three(a, b, c), Two(d, e)) => {
          let left_node = node3(leaf(a), leaf(b), leaf(c))
          let right_node = node3(leaf(middle_val), leaf(d), leaf(e))
          node2(left_node, right_node)
        }
        (Three(a, b, c), Three(d, e, f)) => {
          let left_node = node3(leaf(a), leaf(b), leaf(c))
          let middle_node = node2(leaf(middle_val), leaf(d))
          let right_node = node2(leaf(e), leaf(f))
          node3(left_node, middle_node, right_node)
        }
        (Three(a, b, c), Four(d, e, f, g)) => {
          let left_node = node3(leaf(a), leaf(b), leaf(c))
          let middle_node = node3(leaf(middle_val), leaf(d), leaf(e))
          let right_node = node2(leaf(f), leaf(g))
          node3(left_node, middle_node, right_node)
        }
        (Four(a, b, c, d), One(e)) => {
          let left_node = node3(leaf(a), leaf(b), leaf(c))
          let right_node = node3(leaf(d), leaf(middle_val), leaf(e))
          node2(left_node, right_node)
        }
        (Four(a, b, c, d), Two(e, f)) => {
          let left_node = node3(leaf(a), leaf(b), leaf(c))
          let middle_node = node2(leaf(d), leaf(middle_val))
          let right_node = node2(leaf(e), leaf(f))
          node3(left_node, middle_node, right_node)
        }
        (Four(a, b, c, d), Three(e, f, g)) => {
          let left_node = node3(leaf(a), leaf(b), leaf(c))
          let middle_node = node3(leaf(d), leaf(middle_val), leaf(e))
          let right_node = node2(leaf(f), leaf(g))
          node3(left_node, middle_node, right_node)
        }
        (Four(a, b, c, d), Four(e, f, g, h)) => {
          let left_node = node3(leaf(a), leaf(b), leaf(c))
          let middle_node = node3(leaf(d), leaf(middle_val), leaf(e))
          let right_node = node3(leaf(f), leaf(g), leaf(h))
          node3(left_node, middle_node, right_node)
        }
      }
    }
    (DeepNode(_, left), SingleNode(_, middle_node), DeepNode(_, right)) => {
      let leaf = Tree::single_node(_)
      match (left, right) {
        (One(a), One(b)) => node3(leaf(a), leaf(middle_node), leaf(b))
        (One(a), Two(b, c)) => {
          let left_node = node2(leaf(a), leaf(middle_node))
          let right_node = node2(leaf(b), leaf(c))
          node2(left_node, right_node)
        }
        (One(a), Three(b, c, d)) => {
          let left_node = node2(leaf(a), leaf(middle_node))
          let right_node = node3(leaf(b), leaf(c), leaf(d))
          node2(left_node, right_node)
        }
        (One(a), Four(b, c, d, e)) => {
          let left_node = node3(leaf(a), leaf(middle_node), leaf(b))
          let right_node = node3(leaf(c), leaf(d), leaf(e))
          node2(left_node, right_node)
        }
        (Two(a, b), One(c)) => {
          let left_node = node2(leaf(a), leaf(b))
          let right_node = node2(leaf(middle_node), leaf(c))
          node2(left_node, right_node)
        }
        (Two(a, b), Two(c, d)) => {
          let left_node = node2(leaf(a), leaf(b))
          let middle_node_tree = leaf(middle_node)
          let right_node = node2(leaf(c), leaf(d))
          node3(left_node, middle_node_tree, right_node)
        }
        (Two(a, b), Three(c, d, e)) => {
          let left_node = node3(leaf(a), leaf(b), leaf(middle_node))
          let right_node = node3(leaf(c), leaf(d), leaf(e))
          node2(left_node, right_node)
        }
        (Two(a, b), Four(c, d, e, f)) => {
          let left_node = node3(leaf(a), leaf(b), leaf(middle_node))
          let middle_node_tree = node2(leaf(c), leaf(d))
          let right_node = node2(leaf(e), leaf(f))
          node3(left_node, middle_node_tree, right_node)
        }
        (Three(a, b, c), One(d)) => {
          let left_node = node3(leaf(a), leaf(b), leaf(c))
          let right_node = node2(leaf(middle_node), leaf(d))
          node2(left_node, right_node)
        }
        (Three(a, b, c), Two(d, e)) => {
          let left_node = node3(leaf(a), leaf(b), leaf(c))
          let right_node = node3(leaf(middle_node), leaf(d), leaf(e))
          node2(left_node, right_node)
        }
        (Three(a, b, c), Three(d, e, f)) => {
          let left_node = node3(leaf(a), leaf(b), leaf(c))
          let middle_node_tree = node2(leaf(middle_node), leaf(d))
          let right_node = node2(leaf(e), leaf(f))
          node3(left_node, middle_node_tree, right_node)
        }
        (Three(a, b, c), Four(d, e, f, g)) => {
          let left_node = node3(leaf(a), leaf(b), leaf(c))
          let middle_node_tree = node3(leaf(middle_node), leaf(d), leaf(e))
          let right_node = node2(leaf(f), leaf(g))
          node3(left_node, middle_node_tree, right_node)
        }
        (Four(a, b, c, d), One(e)) => {
          let left_node = node3(leaf(a), leaf(b), leaf(c))
          let right_node = node3(leaf(d), leaf(middle_node), leaf(e))
          node2(left_node, right_node)
        }
        (Four(a, b, c, d), Two(e, f)) => {
          let left_node = node3(leaf(a), leaf(b), leaf(c))
          let middle_node_tree = node2(leaf(d), leaf(middle_node))
          let right_node = node2(leaf(e), leaf(f))
          node3(left_node, middle_node_tree, right_node)
        }
        (Four(a, b, c, d), Three(e, f, g)) => {
          let left_node = node3(leaf(a), leaf(b), leaf(c))
          let middle_node_tree = node3(leaf(d), leaf(middle_node), leaf(e))
          let right_node = node2(leaf(f), leaf(g))
          node3(left_node, middle_node_tree, right_node)
        }
        (Four(a, b, c, d), Four(e, f, g, h)) => {
          let left_node = node3(leaf(a), leaf(b), leaf(c))
          let middle_node_tree = node3(leaf(d), leaf(middle_node), leaf(e))
          let right_node = node3(leaf(f), leaf(g), leaf(h))
          node3(left_node, middle_node_tree, right_node)
        }
      }
    }
    (_, _, _) =>
      abort(
        "dut to type refine to `Deep(Digit[A])` or `DeepNode(Digit[Node[Tree[A]]])`",
      )
  }
}

///|
fn[A] FingerTree::to_list(self : FingerTree[A]) -> List[A] {
  FingerTree::fold_left(self, List::new(), (acc, x) => List::cons(x, acc))
}

///|
/// 用户可见的序列类型 `Seq[A]`
pub(all) struct Seq[A] {
  priv ft : FingerTree[A]
  priv len : Int
}

///|
/// 空序列构造；复杂度：O(1)
pub fn[A] Seq::empty() -> Seq[A] {
  { ft: FingerTree::Empty, len: 0 }
}

///|
/// 单元素序列；复杂度：O(1)
pub fn[A] Seq::singleton(x : A) -> Seq[A] {
  { ft: FingerTree::cons(x, FingerTree::Empty), len: 1 }
}

///|
/// 前插（在左端插入）；均摊 O(1)
pub fn[A] Seq::cons(x : A, s : Seq[A]) -> Seq[A] {
  { ft: FingerTree::cons(x, s.ft), len: s.len + 1 }
}

///|
/// 后插（在右端插入）；均摊 O(1)
pub fn[A] Seq::snoc(s : Seq[A], x : A) -> Seq[A] {
  { ft: FingerTree::snoc(s.ft, x), len: s.len + 1 }
}

///|
/// 拼接两个序列；复杂度：O(log min(n,m))
pub fn[A] Seq::append(a : Seq[A], b : Seq[A]) -> Seq[A] {
  { ft: FingerTree::concat(a.ft, b.ft), len: a.len + b.len }
}

///|
/// 从 List 构造，保持输入顺序；复杂度：O(n)
pub fn[A] Seq::from_list(xs : List[A]) -> Seq[A] {
  // 从左到右 snoc，保持与输入顺序一致
  let mut s = Seq::empty()
  for x in xs {
    s = Seq::snoc(s, x)
  }
  s
}

///|
/// 转为 List；复杂度：O(n)
/// 注意：本实现通过左折配合前插，to_list 展示为“逆序”（更像栈）
pub fn[A] Seq::to_list(s : Seq[A]) -> List[A] {
  s.ft.to_list()
}

///|
/// 判空；复杂度：O(1)
pub fn[A] Seq::null(s : Seq[A]) -> Bool {
  match s.ft {
    FingerTree::Empty => true
    _ => false
  }
}

///|
/// 返回长度；复杂度：O(1)
pub fn[A] Seq::length(s : Seq[A]) -> Int {
  s.len
}

///|
/// 按索引查找（0 基）；复杂度：O(log n)，越界返回 None
pub fn[A] Seq::lookup(s : Seq[A], i : Int) -> A? {
  if i < 0 {
    return None
  }
  FingerTree::lookup(s.ft, i)
}

///|
/// 懒脊版本序列：在 `ft` 上使用 Lazy 包裹以获得均摊操作
pub(all) struct LSeq[A] {
  priv ft : Lazy[FingerTree[A]]
  priv len : Int
}

///|
fn[A] lseq_force_ft(s : LSeq[A]) -> FingerTree[A] {
  Lazy::force(s.ft)
}

///|
/// 懒脊序列空构造；复杂度：O(1)
/// 除非特别说明，LSeq 与 Seq 具有相同阶的复杂度，仅延迟构造与拼接的求值
pub fn[A] LSeq::empty() -> LSeq[A] {
  { ft: Lazy::from_value(FingerTree::Empty), len: 0 }
}

///|
/// 懒脊单元素；复杂度：O(1)
pub fn[A] LSeq::singleton(x : A) -> LSeq[A] {
  { ft: Lazy::from_value(FingerTree::cons(x, FingerTree::Empty)), len: 1 }
}

///|
/// 懒脊前插；建立惰性计算，均摊 O(1)
pub fn[A] LSeq::cons(x : A, s : LSeq[A]) -> LSeq[A] {
  let new_ft = Lazy::new(fn() { FingerTree::cons(x, lseq_force_ft(s)) })
  { ft: new_ft, len: s.len + 1 }
}

///|
/// 懒脊后插；建立惰性计算，均摊 O(1)
pub fn[A] LSeq::snoc(s : LSeq[A], x : A) -> LSeq[A] {
  let new_ft = Lazy::new(fn() { FingerTree::snoc(lseq_force_ft(s), x) })
  { ft: new_ft, len: s.len + 1 }
}

///|
/// 懒脊拼接；复杂度：O(log min(n,m))（在强制时发生）
pub fn[A] LSeq::append(a : LSeq[A], b : LSeq[A]) -> LSeq[A] {
  let new_ft = Lazy::new(fn() {
    FingerTree::concat(lseq_force_ft(a), lseq_force_ft(b))
  })
  { ft: new_ft, len: a.len + b.len }
}

///|
/// 从 List 构造懒脊序列；长度先严格求值，FingerTree 惰性构造
pub fn[A] LSeq::from_list(xs : List[A]) -> LSeq[A] {
  // 构造可按需求值的 ft；长度先严格求值
  let mut n = 0
  for _ in xs {
    n += 1
  }
  let ft_thunk = Lazy::new(fn() { Seq::from_list(xs).ft })
  { ft: ft_thunk, len: n }
}

///|
/// 转为 List；复杂度：O(n)，在过程中会强制求值
pub fn[A] LSeq::to_list(s : LSeq[A]) -> List[A] {
  FingerTree::to_list(lseq_force_ft(s))
}

///|
/// 判空；复杂度：O(1)
pub fn[A] LSeq::null(s : LSeq[A]) -> Bool {
  s.len == 0
}

///|
/// 返回长度；复杂度：O(1)
pub fn[A] LSeq::length(s : LSeq[A]) -> Int {
  s.len
}

///|
/// 按索引查找；复杂度：O(log n)
pub fn[A] LSeq::lookup(s : LSeq[A], i : Int) -> A? {
  // 复用严格版本实现
  Seq::lookup({ ft: lseq_force_ft(s), len: s.len }, i)
}

///|
/// 按索引取值；越界将 abort；复杂度：O(log n)
pub fn[A] LSeq::index(s : LSeq[A], i : Int) -> A {
  Seq::index({ ft: lseq_force_ft(s), len: s.len }, i)
}

///|
/// 取前 n 个；复杂度：O(n)
pub fn[A] LSeq::take(s : LSeq[A], n : Int) -> LSeq[A] {
  if n <= 0 {
    return LSeq::empty()
  }
  if n >= s.len {
    return s
  }
  // 复用严格实现再包装为 Lazy
  let strict_taken = Seq::take({ ft: lseq_force_ft(s), len: s.len }, n)
  { ft: Lazy::from_value(strict_taken.ft), len: strict_taken.len }
}

///|
/// 丢弃前 n 个；复杂度：O(n)
pub fn[A] LSeq::drop(s : LSeq[A], n : Int) -> LSeq[A] {
  if n <= 0 {
    return s
  }
  if n >= s.len {
    return LSeq::empty()
  }
  let strict_dropped = Seq::drop({ ft: lseq_force_ft(s), len: s.len }, n)
  { ft: Lazy::from_value(strict_dropped.ft), len: strict_dropped.len }
}

///|
/// 按位置分割；复杂度：O(log n)
pub fn[A] LSeq::split_at(s : LSeq[A], n : Int) -> (LSeq[A], LSeq[A]) {
  if n <= 0 {
    return (LSeq::empty(), s)
  }
  if n >= s.len {
    return (s, LSeq::empty())
  }
  let (l, r) = Seq::split_at({ ft: lseq_force_ft(s), len: s.len }, n)
  (
    { ft: Lazy::from_value(l.ft), len: l.len },
    { ft: Lazy::from_value(r.ft), len: r.len },
  )
}

///|
/// 映射；复杂度：O(n)，惰性封装结果 FingerTree
pub fn[A, B] LSeq::map(s : LSeq[A], f : (A) -> B) -> LSeq[B] {
  let new_ft = Lazy::new(fn() {
    let strict : Seq[A] = { ft: lseq_force_ft(s), len: s.len }
    Seq::map(strict, f).ft
  })
  { ft: new_ft, len: s.len }
}

///|
/// 带索引映射；复杂度：O(n)
pub fn[A, B] LSeq::map_with_index(s : LSeq[A], f : (Int, A) -> B) -> LSeq[B] {
  let new_ft = Lazy::new(fn() {
    let strict : Seq[A] = { ft: lseq_force_ft(s), len: s.len }
    Seq::map_with_index(strict, f).ft
  })
  { ft: new_ft, len: s.len }
}

///|
/// 反转；复杂度：O(n)，惰性封装
pub fn[A] LSeq::reverse(s : LSeq[A]) -> LSeq[A] {
  let new_ft = Lazy::new(fn() {
    let strict : Seq[A] = { ft: lseq_force_ft(s), len: s.len }
    Seq::reverse(strict).ft
  })
  { ft: new_ft, len: s.len }
}

///|
/// 按位调整；若索引存在则应用 f；复杂度：O(n)
pub fn[A] LSeq::adjust(s : LSeq[A], i : Int, f : (A) -> A) -> LSeq[A] {
  let new_ft = Lazy::new(fn() {
    let strict : Seq[A] = { ft: lseq_force_ft(s), len: s.len }
    Seq::adjust(strict, i, f).ft
  })
  { ft: new_ft, len: s.len }
}

///|
/// 按位更新；复杂度：O(n)
pub fn[A] LSeq::update(s : LSeq[A], i : Int, x : A) -> LSeq[A] {
  let new_ft = Lazy::new(fn() {
    let strict : Seq[A] = { ft: lseq_force_ft(s), len: s.len }
    Seq::update(strict, i, x).ft
  })
  { ft: new_ft, len: s.len }
}

///|
/// 插入；复杂度：O(log n)（通过 split 再拼接）
pub fn[A] LSeq::insert_at(s : LSeq[A], i : Int, x : A) -> LSeq[A] {
  let new_ft = Lazy::new(fn() {
    let strict : Seq[A] = { ft: lseq_force_ft(s), len: s.len }
    Seq::insert_at(strict, i, x).ft
  })
  { ft: new_ft, len: s.len + 1 }
}

///|
/// 删除；复杂度：O(n)
pub fn[A] LSeq::delete_at(s : LSeq[A], i : Int) -> LSeq[A] {
  let new_ft = Lazy::new(fn() {
    let strict : Seq[A] = { ft: lseq_force_ft(s), len: s.len }
    Seq::delete_at(strict, i).ft
  })
  let new_len = if i >= 0 && i < s.len { s.len - 1 } else { s.len }
  { ft: new_ft, len: new_len }
}

///|
pub fn[A] LSeq::uncons(s : LSeq[A]) -> (A?, LSeq[A]) {
  let strict : Seq[A] = { ft: lseq_force_ft(s), len: s.len }
  match Seq::lookup(strict, 0) {
    Some(x) => (Some(x), LSeq::drop(s, 1))
    None => (None, s)
  }
}

///|
pub fn[A] LSeq::unsnoc(s : LSeq[A]) -> (LSeq[A], A?) {
  let n = s.len
  if n <= 0 {
    return (s, None)
  }
  (LSeq::take(s, n - 1), Some(LSeq::index(s, n - 1)))
}

///|
/// 复制 n 份元素；复杂度：O(n)
pub fn[A] LSeq::replicate(n : Int, x : A) -> LSeq[A] {
  if n <= 0 {
    return LSeq::empty()
  }
  let new_ft = Lazy::new(fn() { Seq::replicate(n, x).ft })
  { ft: new_ft, len: n }
}

///|
/// 拉链组合到较短长度；复杂度：O(min(n,m))
pub fn[A, B, C] LSeq::zip_with(
  sa : LSeq[A],
  sb : LSeq[B],
  f : (A, B) -> C,
) -> LSeq[C] {
  let new_ft = Lazy::new(fn() {
    let a_strict : Seq[A] = { ft: lseq_force_ft(sa), len: sa.len }
    let b_strict : Seq[B] = { ft: lseq_force_ft(sb), len: sb.len }
    Seq::zip_with(a_strict, b_strict, f).ft
  })
  let new_len = if sa.len < sb.len { sa.len } else { sb.len }
  { ft: new_ft, len: new_len }
}

///|
/// 拉链；复杂度：O(min(n,m))
pub fn[A, B] LSeq::zip(sa : LSeq[A], sb : LSeq[B]) -> LSeq[(A, B)] {
  LSeq::zip_with(sa, sb, fn(a, b) { (a, b) })
}

///|
/// 解拉链；复杂度：O(n)
pub fn[A, B] LSeq::unzip(s : LSeq[(A, B)]) -> (LSeq[A], LSeq[B]) {
  let ft_a = Lazy::new(fn() {
    let strict : Seq[(A, B)] = { ft: lseq_force_ft(s), len: s.len }
    Seq::unzip(strict).0.ft
  })
  let ft_b = Lazy::new(fn() {
    let strict : Seq[(A, B)] = { ft: lseq_force_ft(s), len: s.len }
    Seq::unzip(strict).1.ft
  })
  let la : LSeq[A] = { ft: ft_a, len: s.len }
  let lb : LSeq[B] = { ft: ft_b, len: s.len }
  (la, lb)
}

///|
/// 左扫描；返回长度 + 1；复杂度：O(n)
pub fn[A, B] LSeq::scanl(s : LSeq[A], init : B, f : (B, A) -> B) -> LSeq[B] {
  let new_ft = Lazy::new(fn() {
    let strict : Seq[A] = { ft: lseq_force_ft(s), len: s.len }
    Seq::scanl(strict, init, f).ft
  })
  { ft: new_ft, len: s.len + 1 }
}

///|
/// 取后 n 个；复杂度：O(n)
pub fn[A] LSeq::take_right(s : LSeq[A], n : Int) -> LSeq[A] {
  if n <= 0 {
    return LSeq::empty()
  }
  if n >= s.len {
    return s
  }
  let new_ft = Lazy::new(fn() {
    let strict : Seq[A] = { ft: lseq_force_ft(s), len: s.len }
    Seq::take_right(strict, n).ft
  })
  { ft: new_ft, len: n }
}

///|
/// 丢弃后 n 个；复杂度：O(n)
pub fn[A] LSeq::drop_right(s : LSeq[A], n : Int) -> LSeq[A] {
  if n <= 0 {
    return s
  }
  if n >= s.len {
    return LSeq::empty()
  }
  let k = s.len - n
  let new_ft = Lazy::new(fn() {
    let strict : Seq[A] = { ft: lseq_force_ft(s), len: s.len }
    Seq::drop_right(strict, n).ft
  })
  { ft: new_ft, len: k }
}

///|
pub fn[A] LSeq::concat(ss : List[LSeq[A]]) -> LSeq[A] {
  // 计算新长度（不强制求值 ft）
  let mut total = 0
  for s in ss {
    total += s.len
  }
  let new_ft = Lazy::new(fn() {
    // 逐个按顺序追加，保持与输入列表相同的拼接顺序
    let mut res : Seq[A] = Seq::empty()
    for s in ss {
      let strict : Seq[A] = { ft: lseq_force_ft(s), len: s.len }
      res = Seq::append(res, strict)
    }
    res.ft
  })
  { ft: new_ft, len: total }
}

///|
pub fn[A] LSeq::filter(s : LSeq[A], p : (A) -> Bool) -> LSeq[A] {
  let strict : Seq[A] = { ft: lseq_force_ft(s), len: s.len }
  let res = Seq::filter(strict, p)
  { ft: Lazy::from_value(res.ft), len: res.len }
}

///|
pub fn[A] LSeq::take_while(s : LSeq[A], p : (A) -> Bool) -> LSeq[A] {
  let strict : Seq[A] = { ft: lseq_force_ft(s), len: s.len }
  let res = Seq::take_while(strict, p)
  { ft: Lazy::from_value(res.ft), len: res.len }
}

///|
pub fn[A] LSeq::drop_while(s : LSeq[A], p : (A) -> Bool) -> LSeq[A] {
  let strict : Seq[A] = { ft: lseq_force_ft(s), len: s.len }
  let res = Seq::drop_while(strict, p)
  { ft: Lazy::from_value(res.ft), len: res.len }
}

///|
pub fn[A] LSeq::take_while_right(s : LSeq[A], p : (A) -> Bool) -> LSeq[A] {
  let strict : Seq[A] = { ft: lseq_force_ft(s), len: s.len }
  let res = Seq::take_while_right(strict, p)
  { ft: Lazy::from_value(res.ft), len: res.len }
}

///|
pub fn[A] LSeq::drop_while_right(s : LSeq[A], p : (A) -> Bool) -> LSeq[A] {
  let strict : Seq[A] = { ft: lseq_force_ft(s), len: s.len }
  let res = Seq::drop_while_right(strict, p)
  { ft: Lazy::from_value(res.ft), len: res.len }
}

///|
pub fn[A] LSeq::partition(s : LSeq[A], p : (A) -> Bool) -> (LSeq[A], LSeq[A]) {
  let strict : Seq[A] = { ft: lseq_force_ft(s), len: s.len }
  let (sa, sb) = Seq::partition(strict, p)
  (
    { ft: Lazy::from_value(sa.ft), len: sa.len },
    { ft: Lazy::from_value(sb.ft), len: sb.len },
  )
}

///|
pub fn[A] LSeq::span(s : LSeq[A], p : (A) -> Bool) -> (LSeq[A], LSeq[A]) {
  let strict : Seq[A] = { ft: lseq_force_ft(s), len: s.len }
  let (l, r) = Seq::span(strict, p)
  (
    { ft: Lazy::from_value(l.ft), len: l.len },
    { ft: Lazy::from_value(r.ft), len: r.len },
  )
}

///|
pub fn[A] LSeq::break_seq(s : LSeq[A], p : (A) -> Bool) -> (LSeq[A], LSeq[A]) {
  let strict : Seq[A] = { ft: lseq_force_ft(s), len: s.len }
  let (l, r) = Seq::break_seq(strict, p)
  (
    { ft: Lazy::from_value(l.ft), len: l.len },
    { ft: Lazy::from_value(r.ft), len: r.len },
  )
}

///|
pub fn[A, B] LSeq::concat_map(s : LSeq[A], f : (A) -> LSeq[B]) -> LSeq[B] {
  let strict_a : Seq[A] = { ft: lseq_force_ft(s), len: s.len }
  let res = Seq::concat_map(strict_a, fn(x) {
    let lb = f(x)
    { ft: lseq_force_ft(lb), len: lb.len }
  })
  { ft: Lazy::from_value(res.ft), len: res.len }
}

///|
/// 按索引取值；越界将 abort；复杂度：O(log n)
pub fn[A] Seq::index(s : Seq[A], i : Int) -> A {
  match Seq::lookup(s, i) {
    Some(x) => x
    None => abort("index out of range")
  }
}

///|
/// 取前 n 个；复杂度：O(n)
pub fn[A] Seq::take(s : Seq[A], n : Int) -> Seq[A] {
  if n <= 0 {
    return Seq::empty()
  }
  if n >= s.len {
    return s
  }
  let mut res = Seq::empty()
  let mut idx = 0
  FingerTree::fold_left(s.ft, (), (_, x) => {
    if idx < n {
      res = Seq::snoc(res, x)
    }
    idx += 1
    ()
  })
  |> ignore
  res
}

///|
/// 丢弃前 n 个；复杂度：O(n)
pub fn[A] Seq::drop(s : Seq[A], n : Int) -> Seq[A] {
  if n <= 0 {
    return s
  }
  if n >= s.len {
    return Seq::empty()
  }
  let mut res = Seq::empty()
  let mut idx = 0
  FingerTree::fold_left(s.ft, (), (_, x) => {
    if idx >= n {
      res = Seq::snoc(res, x)
    }
    idx += 1
    ()
  })
  |> ignore
  res
}

///|
/// 按位置分割 (n)；复杂度：O(log n)
pub fn[A] Seq::split_at(s : Seq[A], n : Int) -> (Seq[A], Seq[A]) {
  if n <= 0 {
    return (Seq::empty(), s)
  }
  if n >= s.len {
    return (s, Seq::empty())
  }
  let (lft, rft) = FingerTree::split_at(s.ft, n)
  ({ ft: lft, len: n }, { ft: rft, len: s.len - n })
}

///|
/// 在索引处插入；复杂度：O(log n)（split + append）
pub fn[A] Seq::insert_at(s : Seq[A], i : Int, x : A) -> Seq[A] {
  if i <= 0 {
    return Seq::cons(x, s)
  }
  let len = Seq::length(s)
  if i >= len {
    return Seq::snoc(s, x)
  }
  let (l, r) = Seq::split_at(s, i)
  Seq::append(Seq::append(l, Seq::singleton(x)), r)
}

///|
/// 删除索引处元素；复杂度：O(n)
pub fn[A] Seq::delete_at(s : Seq[A], i : Int) -> Seq[A] {
  if i < 0 {
    return s
  }
  let mut res = Seq::empty()
  let mut idx = 0
  FingerTree::fold_left(s.ft, (), (_, x) => {
    if idx != i {
      res = Seq::snoc(res, x)
    }
    idx += 1
    ()
  })
  |> ignore
  res
}

///|
/// 更新索引处元素；复杂度：O(n)
pub fn[A] Seq::update(s : Seq[A], i : Int, x : A) -> Seq[A] {
  if i < 0 {
    return s
  }
  let mut res = Seq::empty()
  let mut idx = 0
  FingerTree::fold_left(s.ft, (), (_, a) => {
    if idx == i {
      res = Seq::snoc(res, x)
    } else {
      res = Seq::snoc(res, a)
    }
    idx += 1
    ()
  })
  |> ignore
  res
}

///|
/// 映射；复杂度：O(n)
pub fn[A, B] Seq::map(s : Seq[A], f : (A) -> B) -> Seq[B] {
  let mut res = Seq::empty()
  FingerTree::fold_left(s.ft, (), (_, x) => {
    res = Seq::snoc(res, f(x))
    ()
  })
  |> ignore
  res
}

///|
/// 带索引映射；复杂度：O(n)
pub fn[A, B] Seq::map_with_index(s : Seq[A], f : (Int, A) -> B) -> Seq[B] {
  let mut res = Seq::empty()
  let mut idx = 0
  FingerTree::fold_left(s.ft, (), (_, x) => {
    res = Seq::snoc(res, f(idx, x))
    idx += 1
    ()
  })
  |> ignore
  res
}

///|
/// 过滤；复杂度：O(n)
pub fn[A] Seq::filter(s : Seq[A], p : (A) -> Bool) -> Seq[A] {
  let mut res = Seq::empty()
  FingerTree::fold_left(s.ft, (), (_, x) => {
    if p(x) {
      res = Seq::snoc(res, x)
    }
    ()
  })
  |> ignore
  res
}

///|
/// 反转；复杂度：O(n)
pub fn[A] Seq::reverse(s : Seq[A]) -> Seq[A] {
  // 左折配合前插，得到反转
  let mut res = Seq::empty()
  FingerTree::fold_left(s.ft, (), (_, x) => {
    res = Seq::cons(x, res)
    ()
  })
  |> ignore
  res
}

///|
/// 从左侧取出一个元素与剩余序列
pub fn[A] Seq::uncons(s : Seq[A]) -> (A?, Seq[A]) {
  match Seq::lookup(s, 0) {
    Some(x) => (Some(x), Seq::drop(s, 1))
    None => (None, s)
  }
}

///|
/// 从右侧取出一个元素与剩余序列（返回 (init, last)）
pub fn[A] Seq::unsnoc(s : Seq[A]) -> (Seq[A], A?) {
  let n = s.len
  if n <= 0 {
    return (s, None)
  }
  (Seq::take(s, n - 1), Some(Seq::index(s, n - 1)))
}

///|
pub fn[A] Seq::take_while(s : Seq[A], p : (A) -> Bool) -> Seq[A] {
  let mut res = Seq::empty()
  let mut taking = true
  FingerTree::fold_left(s.ft, (), (_, x) => {
    if taking && p(x) {
      res = Seq::snoc(res, x)
    } else {
      taking = false
    }
    ()
  })
  |> ignore
  res
}

///|
pub fn[A] Seq::drop_while(s : Seq[A], p : (A) -> Bool) -> Seq[A] {
  let mut res = Seq::empty()
  let mut dropping = true
  FingerTree::fold_left(s.ft, (), (_, x) => {
    if dropping && p(x) {
      // skip
    } else {
      dropping = false
      res = Seq::snoc(res, x)
    }
    ()
  })
  |> ignore
  res
}

///|
/// 命名别名：与 Data.Sequence.takeWhileL 对齐
pub fn[A] Seq::take_while_left(s : Seq[A], p : (A) -> Bool) -> Seq[A] {
  Seq::take_while(s, p)
}

///|
/// 命名别名：与 Data.Sequence.dropWhileL 对齐
pub fn[A] Seq::drop_while_left(s : Seq[A], p : (A) -> Bool) -> Seq[A] {
  Seq::drop_while(s, p)
}

///|
/// 从右侧持续满足谓词的元素构成的后缀
pub fn[A] Seq::take_while_right(s : Seq[A], p : (A) -> Bool) -> Seq[A] {
  Seq::reverse(Seq::take_while(Seq::reverse(s), p))
}

///|
/// 从右侧丢弃持续满足谓词的元素
pub fn[A] Seq::drop_while_right(s : Seq[A], p : (A) -> Bool) -> Seq[A] {
  Seq::reverse(Seq::drop_while(Seq::reverse(s), p))
}

///|
/// 右侧版本 span（与 Data.Sequence.spanr 对齐）
pub fn[A] Seq::span_right(s : Seq[A], p : (A) -> Bool) -> (Seq[A], Seq[A]) {
  (Seq::drop_while_right(s, p), Seq::take_while_right(s, p))
}

///|
/// 右侧版本 break（与 Data.Sequence.breakr 对齐）
pub fn[A] Seq::break_right(s : Seq[A], p : (A) -> Bool) -> (Seq[A], Seq[A]) {
  Seq::span_right(s, fn(x) { !p(x) })
}

///|
/// 就地调整（若索引存在则应用 f）；复杂度：O(n)
pub fn[A] Seq::adjust(s : Seq[A], i : Int, f : (A) -> A) -> Seq[A] {
  match Seq::lookup(s, i) {
    Some(v) => Seq::update(s, i, f(v))
    None => s
  }
}

///|
/// 复制 n 份元素；复杂度：O(n)
pub fn[A] Seq::replicate(n : Int, x : A) -> Seq[A] {
  fn go(k : Int, acc : Seq[A]) -> Seq[A] {
    if k <= 0 {
      return acc
    }
    go(k - 1, Seq::snoc(acc, x))
  }

  if n <= 0 {
    Seq::empty()
  } else {
    go(n, Seq::empty())
  }
}

///|
/// 从种子按步进函数向右展开（与 Haskell Data.Sequence.unfoldr 对齐）
pub fn[A, S] Seq::unfoldr(step : (S) -> (A, S)?, seed : S) -> Seq[A] {
  let mut res : Seq[A] = Seq::empty()
  let mut st = seed
  let mut cont = true
  while cont {
    match step(st) {
      Some(pair) => {
        let (a, st2) = pair
        res = Seq::snoc(res, a)
        st = st2
      }
      None => cont = false
    }
  }
  res
}

///|
/// 从种子按步进函数向左展开（与 Haskell Data.Sequence.unfoldl 对齐）
pub fn[A, S] Seq::unfoldl(step : (S) -> (S, A)?, seed : S) -> Seq[A] {
  let mut res : Seq[A] = Seq::empty()
  let mut st = seed
  let mut cont = true
  while cont {
    match step(st) {
      Some(pair) => {
        let (st2, a) = pair
        res = Seq::cons(a, res)
        st = st2
      }
      None => cont = false
    }
  }
  res
}

///|
/// 拉链组合到较短长度；复杂度：O(min(n,m))
pub fn[A, B, C] Seq::zip_with(
  sa : Seq[A],
  sb : Seq[B],
  f : (A, B) -> C,
) -> Seq[C] {
  let mut res = Seq::empty()
  let len_b = sb.len
  let mut i = 0
  FingerTree::fold_left(sa.ft, (), (_, a) => {
    if i < len_b {
      let b = Seq::index(sb, i)
      res = Seq::snoc(res, f(a, b))
      i += 1
    }
    ()
  })
  |> ignore
  res
}

///|
/// 左扫描；返回长度 + 1；复杂度：O(n)
pub fn[A, B] Seq::scanl(s : Seq[A], init : B, f : (B, A) -> B) -> Seq[B] {
  let mut acc = init
  let mut res = Seq::singleton(init)
  FingerTree::fold_left(s.ft, (), (_, x) => {
    acc = f(acc, x)
    res = Seq::snoc(res, acc)
    ()
  })
  |> ignore
  res
}

///|
/// 右扫描：与 Haskell Data.Sequence.scanr 一致
pub fn[A, B] Seq::scanr(s : Seq[A], init : B, f : (A, B) -> B) -> Seq[B] {
  // 利用反转与 scanl 实现：scanr f z xs = reverse (scanl g z (reverse xs))
  // 其中 g acc a = f a acc
  let rev = Seq::reverse(s)
  let res_rev = Seq::scanl(rev, init, fn(acc, a) { f(a, acc) })
  Seq::reverse(res_rev)
}

///|
/// 拉链；复杂度：O(min(n,m))
pub fn[A, B] Seq::zip(sa : Seq[A], sb : Seq[B]) -> Seq[(A, B)] {
  Seq::zip_with(sa, sb, fn(a, b) { (a, b) })
}

///|
/// 解拉链；复杂度：O(n)
pub fn[A, B] Seq::unzip(s : Seq[(A, B)]) -> (Seq[A], Seq[B]) {
  let mut sa = Seq::empty()
  let mut sb = Seq::empty()
  FingerTree::fold_left(s.ft, (), (_, p) => {
    let (a, b) = p
    sa = Seq::snoc(sa, a)
    sb = Seq::snoc(sb, b)
    ()
  })
  |> ignore
  (sa, sb)
}

///|
/// 按谓词划分；复杂度：O(n)
pub fn[A] Seq::partition(s : Seq[A], p : (A) -> Bool) -> (Seq[A], Seq[A]) {
  let mut yes = Seq::empty()
  let mut no = Seq::empty()
  FingerTree::fold_left(s.ft, (), (_, x) => {
    if p(x) {
      yes = Seq::snoc(yes, x)
    } else {
      no = Seq::snoc(no, x)
    }
    ()
  })
  |> ignore
  (yes, no)
}

///|
/// span：最长前缀满足 p，与剩余；复杂度：O(n)
pub fn[A] Seq::span(s : Seq[A], p : (A) -> Bool) -> (Seq[A], Seq[A]) {
  (Seq::take_while(s, p), Seq::drop_while(s, p))
}

///|
pub fn[A] Seq::break_seq(s : Seq[A], p : (A) -> Bool) -> (Seq[A], Seq[A]) {
  Seq::span(s, fn(x) { !p(x) })
}

///|
/// 取后 n 个；复杂度：O(n)
pub fn[A] Seq::take_right(s : Seq[A], n : Int) -> Seq[A] {
  if n <= 0 {
    return Seq::empty()
  }
  if n >= s.len {
    return s
  }
  let k = s.len - n
  Seq::drop(s, k)
}

///|
/// 丢弃后 n 个；复杂度：O(n)
pub fn[A] Seq::drop_right(s : Seq[A], n : Int) -> Seq[A] {
  if n <= 0 {
    return s
  }
  if n >= s.len {
    return Seq::empty()
  }
  let k = s.len - n
  Seq::take(s, k)
}

///|
/// 拼接一组序列
pub fn[A] Seq::concat(ss : List[Seq[A]]) -> Seq[A] {
  let mut res = Seq::empty()
  for s in ss {
    res = Seq::append(res, s)
  }
  res
}

///|
/// 映射为序列后再拼接（flatMap）
pub fn[A, B] Seq::concat_map(s : Seq[A], f : (A) -> Seq[B]) -> Seq[B] {
  let mut res = Seq::empty()
  FingerTree::fold_left(s.ft, (), (_, x) => {
    res = Seq::append(res, f(x))
    ()
  })
  |> ignore
  res
}
