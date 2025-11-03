///|
test "basic construction" (_t : @test.T) {
  let s : Seq[Int] = Seq::empty()
  inspect(Seq::null(s), content="true")
  let s1 = Seq::singleton(1)
  inspect(Seq::null(s1), content="false")
  inspect(Seq::length(s1), content="1")
  let s2 = Seq::cons(0, s1)
  let s3 = Seq::snoc(s2, 2)
  inspect(Seq::to_list(s3), content="@list.from_array([2, 1, 0])")
}

///|
test "append and from_list" (_t : @test.T) {
  let s = Seq::from_list(@list.from_array([1, 2, 3]))
  let t1 = Seq::from_list(@list.from_array([4, 5]))
  let u = Seq::append(s, t1)
  inspect(Seq::to_list(u), content="@list.from_array([5, 4, 3, 2, 1])")
}

///|
test "lookup index take drop split_at" (_t : @test.T) {
  let s = Seq::from_list(@list.from_array([10, 20, 30, 40, 50]))
  inspect(Seq::lookup(s, 0), content="Some(10)")
  inspect(Seq::lookup(s, 4), content="Some(50)")
  inspect(Seq::lookup(s, 5), content="None")
  inspect(Seq::index(s, 3), content="40")
  let a = Seq::take(s, 3)
  let b = Seq::drop(s, 3)
  inspect(Seq::to_list(a), content="@list.from_array([30, 20, 10])")
  inspect(Seq::to_list(b), content="@list.from_array([50, 40])")
  let (l, r) = Seq::split_at(s, 2)
  inspect(Seq::to_list(l), content="@list.from_array([20, 10])")
  inspect(Seq::to_list(r), content="@list.from_array([50, 40, 30])")
}

///|
test "update insert delete map filter reverse" (_t : @test.T) {
  let s = Seq::from_list(@list.from_array([1, 2, 3, 4]))
  let s1 = Seq::update(s, 1, 20)
  inspect(Seq::to_list(s1), content="@list.from_array([4, 3, 20, 1])")
  let s2 = Seq::insert_at(s1, 2, 99)
  inspect(Seq::to_list(s2), content="@list.from_array([4, 3, 99, 20, 1])")
  let s3 = Seq::delete_at(s2, 3)
  inspect(Seq::to_list(s3), content="@list.from_array([4, 99, 20, 1])")
  let s4 = Seq::map(s3, fn(x) { x * 2 })
  inspect(Seq::to_list(s4), content="@list.from_array([8, 198, 40, 2])")
  let s5 = Seq::map_with_index(s3, fn(i, x) { x + i })
  inspect(Seq::to_list(s5), content="@list.from_array([7, 101, 21, 1])")
  let s6 = Seq::filter(s5, fn(x) { x % 2 == 0 })
  inspect(Seq::to_list(s6), content="@list.from_array([])")
  inspect(Seq::to_list(Seq::reverse(s6)), content="@list.from_array([])")
}

///|
test "uncons unsnoc take_while drop_while adjust replicate zip_with scanl" (
  _t : @test.T,
) {
  let s = Seq::from_list(@list.from_array([1, 2, 3, 4, 5]))
  let (h, t) = Seq::uncons(s)
  inspect(h, content="Some(1)")
  inspect(Seq::to_list(t), content="@list.from_array([5, 4, 3, 2])")
  let (init, last) = Seq::unsnoc(s)
  inspect(Seq::to_list(init), content="@list.from_array([4, 3, 2, 1])")
  inspect(last, content="Some(5)")
  let tw = Seq::take_while(s, fn(x) { x < 4 })
  inspect(Seq::to_list(tw), content="@list.from_array([3, 2, 1])")
  let dw = Seq::drop_while(s, fn(x) { x < 4 })
  inspect(Seq::to_list(dw), content="@list.from_array([5, 4])")
  let adj = Seq::adjust(s, 2, fn(x) { x * 10 })
  inspect(Seq::to_list(adj), content="@list.from_array([5, 4, 30, 2, 1])")
  let rep = Seq::replicate(3, 7)
  inspect(Seq::to_list(rep), content="@list.from_array([7, 7, 7])")
  let s1 = Seq::from_list(@list.from_array([1, 2, 3]))
  let s2 = Seq::from_list(@list.from_array([10, 20]))
  let zw = Seq::zip_with(s1, s2, fn(a, b) { a + b })
  inspect(Seq::to_list(zw), content="@list.from_array([22, 11])")
  let sc = Seq::scanl(s1, 0, fn(acc, x) { acc + x })
  inspect(Seq::to_list(sc), content="@list.from_array([6, 3, 1, 0])")
}

///|
test "zip unzip partition span break take_right drop_right" (_t : @test.T) {
  // zip & unzip
  let s1 = Seq::from_list(@list.from_array([1, 2, 3]))
  let s2 = Seq::from_list(@list.from_array([10, 20, 30, 40]))
  let zipped = Seq::zip(s1, s2)
  let (u1, u2) = Seq::unzip(zipped)
  inspect(Seq::to_list(u1), content="@list.from_array([3, 2, 1])")
  inspect(Seq::to_list(u2), content="@list.from_array([30, 20, 10])")

  // partition
  let psrc = Seq::from_list(@list.from_array([1, 2, 3, 4, 5, 6]))
  let (evens, odds) = Seq::partition(psrc, fn(x) { x % 2 == 0 })
  inspect(Seq::to_list(evens), content="@list.from_array([6, 4, 2])")
  inspect(Seq::to_list(odds), content="@list.from_array([5, 3, 1])")

  // span & break
  let s3 = Seq::from_list(@list.from_array([1, 2, 3, 4, 1]))
  let (sp_l, sp_r) = Seq::span(s3, fn(x) { x < 4 })
  inspect(Seq::to_list(sp_l), content="@list.from_array([3, 2, 1])")
  inspect(Seq::to_list(sp_r), content="@list.from_array([1, 4])")
  let (bk_l, bk_r) = Seq::break_seq(s3, fn(x) { x >= 4 })
  inspect(Seq::to_list(bk_l), content="@list.from_array([3, 2, 1])")
  inspect(Seq::to_list(bk_r), content="@list.from_array([1, 4])")

  // take_right & drop_right
  let s4 = Seq::from_list(@list.from_array([10, 20, 30, 40, 50]))
  inspect(
    Seq::to_list(Seq::take_right(s4, 2)),
    content="@list.from_array([50, 40])",
  )
  inspect(
    Seq::to_list(Seq::drop_right(s4, 2)),
    content="@list.from_array([30, 20, 10])",
  )
}

///|
test "take_while_right and drop_while_right" (_t : @test.T) {
  let s = Seq::from_list(@list.from_array([1, 2, 3, 4, 5, 6]))
  let twr = Seq::take_while_right(s, fn(x) { x > 3 })
  inspect(Seq::to_list(twr), content="@list.from_array([6, 5, 4])")
  let dwr = Seq::drop_while_right(s, fn(x) { x > 3 })
  inspect(Seq::to_list(dwr), content="@list.from_array([3, 2, 1])")
  let all = Seq::take_while_right(s, fn(_x) { true })
  inspect(Seq::to_list(all), content="@list.from_array([6, 5, 4, 3, 2, 1])")
  let none = Seq::drop_while_right(s, fn(_x) { false })
  inspect(Seq::to_list(none), content="@list.from_array([6, 5, 4, 3, 2, 1])")
}

///|
test "concat and concat_map" (_t : @test.T) {
  let s1 = Seq::from_list(@list.from_array([1, 2]))
  let s2 = Seq::from_list(@list.from_array([3]))
  let s3 : Seq[Int] = Seq::empty()
  let s4 = Seq::from_list(@list.from_array([4, 5]))
  let conc = Seq::concat(@list.from_array([s1, s2, s3, s4]))
  inspect(Seq::to_list(conc), content="@list.from_array([5, 4, 3, 2, 1])")
  let cm = Seq::concat_map(Seq::from_list(@list.from_array([1, 2, 3, 4])), fn(
    x,
  ) {
    if x % 2 == 0 {
      Seq::from_list(@list.from_array([x, x + 100]))
    } else {
      Seq::empty()
    }
  })
  inspect(Seq::to_list(cm), content="@list.from_array([104, 4, 102, 2])")
  let cm2 = Seq::concat_map(Seq::from_list(@list.from_array([1, 2, 3])), fn(x) {
    Seq::from_list(@list.from_array([x, x]))
  })
  inspect(Seq::to_list(cm2), content="@list.from_array([3, 3, 2, 2, 1, 1])")
}

///|
test "black-box deep shapes via append/cons/snoc" (_t : @test.T) {
  // Build long sequences using only public Seq APIs
  let mut long1 : Seq[Int] = Seq::empty()
  let mut i = 1
  while i <= 60 {
    long1 = Seq::snoc(long1, i)
    i += 1
  }
  let mut long2 : Seq[Int] = Seq::empty()
  let mut j = 61
  while j <= 120 {
    long2 = Seq::snoc(long2, j)
    j += 1
  }

  // Deep append
  let app = Seq::append(long1, long2)
  inspect(Seq::length(app), content="120")
  inspect(Seq::index(app, 0), content="1")
  inspect(Seq::index(app, 59), content="60")
  inspect(Seq::index(app, 60), content="61")
  inspect(Seq::index(app, 119), content="120")

  // Stress cons and snoc alternation to trigger both sides growth
  let mut s : Seq[Int] = Seq::empty()
  let mut x = 1
  while x <= 50 {
    s = Seq::cons(x, s)
    s = Seq::snoc(s, x)
    x += 1
  }
  inspect(Seq::length(s), content="100")
  // Expected shape: [50..1] ++ [1..50]
  inspect(Seq::index(s, 0), content="50")
  inspect(Seq::index(s, 1), content="49")
  inspect(Seq::index(s, 49), content="1")
  inspect(Seq::index(s, 50), content="1")
  inspect(Seq::index(s, 99), content="50")

  // Force middle-tree building through varying chunk sizes in concat_map
  let mut chunked : Seq[Int] = Seq::empty()
  let mut y = 1
  while y <= 20 {
    chunked = Seq::snoc(chunked, y)
    y += 1
  }
  let cm = Seq::concat_map(chunked, fn(x) {
    if x % 4 == 0 {
      Seq::from_list(@list.from_array([x, x + 100, x + 200, x + 300]))
    } else if x % 4 == 1 {
      Seq::singleton(x)
    } else if x % 4 == 2 {
      Seq::from_list(@list.from_array([x, x + 10]))
    } else {
      Seq::from_list(@list.from_array([x, x + 20, x + 40]))
    }
  })
  inspect(Seq::length(cm), content="50")
  inspect(Seq::index(cm, 0), content="1")
  inspect(Seq::index(cm, 1), content="2")
  inspect(Seq::index(cm, 2), content="12")
  inspect(Seq::index(cm, 3), content="3")
  inspect(Seq::index(cm, 9), content="304")
  inspect(Seq::index(cm, 46), content="20")
  inspect(Seq::index(cm, 47), content="120")
  inspect(Seq::index(cm, 48), content="220")
  inspect(Seq::index(cm, 49), content="320")
}

///|
test "edge cases and boundaries" (_t : @test.T) {
  let s = Seq::from_list(@list.from_array([10, 20, 30]))
  let emptyInt : Seq[Int] = Seq::empty()

  // lookup negative
  inspect(Seq::lookup(s, -1), content="None")

  // uncons/unsnoc on empty
  let (h0, t0) = Seq::uncons(emptyInt)
  inspect(h0, content="None")
  inspect(Seq::to_list(t0), content="@list.from_array([])")
  let (i0, l0) = Seq::unsnoc(emptyInt)
  inspect(Seq::to_list(i0), content="@list.from_array([])")
  inspect(l0, content="None")

  // update/delete out-of-range
  let upd1 = Seq::update(s, -1, 99)
  inspect(Seq::to_list(upd1), content="@list.from_array([30, 20, 10])")
  let upd2 = Seq::update(s, 10, 99)
  inspect(Seq::to_list(upd2), content="@list.from_array([30, 20, 10])")
  let adj1 = Seq::adjust(s, -1, fn(x) { x + 1 })
  inspect(Seq::to_list(adj1), content="@list.from_array([30, 20, 10])")
  let adj2 = Seq::adjust(s, 10, fn(x) { x + 1 })
  inspect(Seq::to_list(adj2), content="@list.from_array([30, 20, 10])")
  let del1 = Seq::delete_at(s, -2)
  inspect(Seq::to_list(del1), content="@list.from_array([30, 20, 10])")
  let del2 = Seq::delete_at(s, 10)
  inspect(Seq::to_list(del2), content="@list.from_array([30, 20, 10])")

  // partition empty
  let (pa, pb) = Seq::partition(emptyInt, fn(_x) { true })
  inspect(Seq::to_list(pa), content="@list.from_array([])")
  inspect(Seq::to_list(pb), content="@list.from_array([])")
  // filter positive path
  let fil = Seq::filter(s, fn(x) { x > 15 })
  inspect(Seq::to_list(fil), content="@list.from_array([30, 20])")

  // scanl empty
  let sc0 = Seq::scanl(Seq::empty(), 0, fn(acc, x) { acc + x })
  inspect(Seq::to_list(sc0), content="@list.from_array([0])")

  // take_right/drop_right boundaries
  let tr0 = Seq::take_right(s, 0)
  inspect(Seq::to_list(tr0), content="@list.from_array([])")
  let dr0 = Seq::drop_right(s, 0)
  inspect(Seq::to_list(dr0), content="@list.from_array([30, 20, 10])")
  let tr_big = Seq::take_right(s, 99)
  inspect(Seq::to_list(tr_big), content="@list.from_array([30, 20, 10])")
  let dr_big = Seq::drop_right(s, 99)
  inspect(Seq::to_list(dr_big), content="@list.from_array([])")

  // split_at boundaries
  let (sa0_l, sa0_r) = Seq::split_at(s, 0)
  inspect(Seq::to_list(sa0_l), content="@list.from_array([])")
  inspect(Seq::to_list(sa0_r), content="@list.from_array([30, 20, 10])")
  let (sa_big_l, sa_big_r) = Seq::split_at(s, 99)
  inspect(Seq::to_list(sa_big_l), content="@list.from_array([30, 20, 10])")
  inspect(Seq::to_list(sa_big_r), content="@list.from_array([])")

  // take/drop boundaries
  let t0 = Seq::take(s, 0)
  inspect(Seq::to_list(t0), content="@list.from_array([])")
  let t_big = Seq::take(s, 99)
  inspect(Seq::to_list(t_big), content="@list.from_array([30, 20, 10])")
  let dbig = Seq::drop(s, 99)
  inspect(Seq::to_list(dbig), content="@list.from_array([])")
  let d0 = Seq::drop(s, 0)
  inspect(Seq::to_list(d0), content="@list.from_array([30, 20, 10])")

  // insert_at boundaries
  let ins0 = Seq::insert_at(s, 0, 5)
  inspect(Seq::to_list(ins0), content="@list.from_array([30, 20, 10, 5])")
  let ins_big = Seq::insert_at(s, 99, 7)
  inspect(Seq::to_list(ins_big), content="@list.from_array([7, 30, 20, 10])")

  // replicate boundary
  let rep0 = Seq::replicate(0, 1)
  inspect(Seq::to_list(rep0), content="@list.from_array([])")
}

///|
test "append middles: Single vs Single" (_t : @test.T) {
  // Build left with one push into middle via snoc -> middle becomes Single
  let mut left : Seq[Int] = Seq::empty()
  let mut i = 1
  while i <= 6 {
    left = Seq::snoc(left, i)
    i += 1
  }

  // Build right with one push into middle via cons -> middle becomes Single
  let mut right : Seq[Int] = Seq::empty()
  let mut j = 7
  while j <= 12 {
    right = Seq::cons(j, right)
    j += 1
  }
  let s = Seq::append(left, right)
  inspect(Seq::length(s), content="12")
  inspect(Seq::index(s, 0), content="1")
  inspect(Seq::index(s, 5), content="6")
  inspect(Seq::index(s, 6), content="12")
  inspect(Seq::index(s, 11), content="7")
}

///|
test "append middles: Deep vs Single" (_t : @test.T) {
  // Build left large enough to create a deeper middle (not Single)
  let mut left : Seq[Int] = Seq::empty()
  let mut i = 1
  while i <= 20 {
    left = Seq::snoc(left, i)
    i += 1
  }

  // Build right with exactly one middle node
  let mut right : Seq[Int] = Seq::empty()
  let mut j = 21
  while j <= 26 {
    right = Seq::cons(j, right)
    j += 1
  }
  let s = Seq::append(left, right)
  inspect(Seq::length(s), content="26")
  inspect(Seq::index(s, 0), content="1")
  inspect(Seq::index(s, 19), content="20")
  inspect(Seq::index(s, 20), content="26")
  inspect(Seq::index(s, 25), content="21")
}

///|
test "append middles: Empty vs Single" (_t : @test.T) {
  // Left: minimal deep (2 elements) -> middle is Empty
  let mut left : Seq[Int] = Seq::empty()
  left = Seq::snoc(left, 1)
  left = Seq::snoc(left, 2)

  // Right: one middle node via cons 6 times
  let mut right : Seq[Int] = Seq::empty()
  let mut j = 3
  while j <= 8 {
    right = Seq::cons(j, right)
    j += 1
  }
  let s = Seq::append(left, right)
  inspect(Seq::length(s), content="8")
  inspect(Seq::index(s, 0), content="1")
  inspect(Seq::index(s, 1), content="2")
  inspect(Seq::index(s, 2), content="8")
  inspect(Seq::index(s, 7), content="3")
}

///|
test "LSeq basics and ops" (_t : @test.T) {
  // 构造与 to_list
  let s = LSeq::from_list(@list.from_array([1, 2, 3]))
  inspect(LSeq::to_list(s), content="@list.from_array([3, 2, 1])")

  // append/cons/snoc
  let a = LSeq::append(LSeq::singleton(0), s)
  inspect(LSeq::to_list(a), content="@list.from_array([3, 2, 1, 0])")
  let b = LSeq::cons(9, a)
  inspect(LSeq::to_list(b), content="@list.from_array([3, 2, 1, 0, 9])")
  let c = LSeq::snoc(b, 8)
  inspect(LSeq::to_list(c), content="@list.from_array([8, 3, 2, 1, 0, 9])")

  // length / lookup / index
  inspect(LSeq::length(c), content="6")
  inspect(LSeq::lookup(c, 0), content="Some(9)")
  inspect(LSeq::lookup(c, 5), content="Some(8)")
  inspect(LSeq::lookup(c, 6), content="None")
  inspect(LSeq::index(c, 3), content="2")

  // take / drop / split_at
  let t = LSeq::take(c, 3)
  inspect(LSeq::to_list(t), content="@list.from_array([1, 0, 9])")
  let d = LSeq::drop(c, 3)
  inspect(LSeq::to_list(d), content="@list.from_array([8, 3, 2])")
  let (l, r) = LSeq::split_at(c, 2)
  inspect(LSeq::to_list(l), content="@list.from_array([0, 9])")
  inspect(LSeq::to_list(r), content="@list.from_array([8, 3, 2, 1])")
}

///|
test "LSeq more ops" (_t : @test.T) {
  // base
  let s = LSeq::from_list(@list.from_array([1, 2, 3, 4]))

  // map / map_with_index
  let m = LSeq::map(s, fn(x) { x * 2 })
  inspect(LSeq::to_list(m), content="@list.from_array([8, 6, 4, 2])")
  let mi = LSeq::map_with_index(s, fn(i, x) { x + i })
  inspect(LSeq::to_list(mi), content="@list.from_array([7, 5, 3, 1])")

  // reverse
  inspect(
    LSeq::to_list(LSeq::reverse(s)),
    content="@list.from_array([1, 2, 3, 4])",
  )

  // update / adjust / insert_at / delete_at
  let u = LSeq::update(s, 1, 20)
  inspect(LSeq::to_list(u), content="@list.from_array([4, 3, 20, 1])")
  let a = LSeq::adjust(s, 2, fn(x) { x * 10 })
  inspect(LSeq::to_list(a), content="@list.from_array([4, 30, 2, 1])")
  let ins = LSeq::insert_at(s, 2, 99)
  inspect(LSeq::to_list(ins), content="@list.from_array([4, 3, 99, 2, 1])")
  let del = LSeq::delete_at(ins, 3)
  inspect(LSeq::to_list(del), content="@list.from_array([4, 99, 2, 1])")

  // uncons / unsnoc
  let s5 = LSeq::from_list(@list.from_array([1, 2, 3, 4, 5]))
  let (h, t) = LSeq::uncons(s5)
  inspect(h, content="Some(1)")
  inspect(LSeq::to_list(t), content="@list.from_array([5, 4, 3, 2])")
  let (init, last) = LSeq::unsnoc(s5)
  inspect(LSeq::to_list(init), content="@list.from_array([4, 3, 2, 1])")
  inspect(last, content="Some(5)")

  // replicate
  let rep = LSeq::replicate(3, 7)
  inspect(LSeq::to_list(rep), content="@list.from_array([7, 7, 7])")

  // zip_with / zip / unzip
  let z1 = LSeq::from_list(@list.from_array([1, 2, 3]))
  let z2 = LSeq::from_list(@list.from_array([10, 20]))
  let zw = LSeq::zip_with(z1, z2, fn(a, b) { a + b })
  inspect(LSeq::to_list(zw), content="@list.from_array([22, 11])")
  let z = LSeq::zip(z1, LSeq::from_list(@list.from_array([100, 200, 300])))
  let (zu1, zu2) = LSeq::unzip(z)
  inspect(LSeq::to_list(zu1), content="@list.from_array([3, 2, 1])")
  inspect(LSeq::to_list(zu2), content="@list.from_array([300, 200, 100])")

  // scanl
  let sc = LSeq::scanl(LSeq::from_list(@list.from_array([1, 2, 3])), 0, fn(
    acc,
    x,
  ) {
    acc + x
  })
  inspect(LSeq::to_list(sc), content="@list.from_array([6, 3, 1, 0])")

  // take_right / drop_right
  let s6 = LSeq::from_list(@list.from_array([10, 20, 30, 40, 50]))
  inspect(
    LSeq::to_list(LSeq::take_right(s6, 2)),
    content="@list.from_array([50, 40])",
  )
  inspect(
    LSeq::to_list(LSeq::drop_right(s6, 2)),
    content="@list.from_array([30, 20, 10])",
  )

  // concat
  let c1 = LSeq::from_list(@list.from_array([1, 2]))
  let c2 = LSeq::from_list(@list.from_array([3]))
  let c3 : LSeq[Int] = LSeq::empty()
  let c4 = LSeq::from_list(@list.from_array([4, 5]))
  let conc = LSeq::concat(@list.from_array([c1, c2, c3, c4]))
  inspect(LSeq::to_list(conc), content="@list.from_array([5, 4, 3, 2, 1])")
}

///|
test "LSeq filter/partition/span/break and while variants" (_t : @test.T) {
  let s = LSeq::from_list(@list.from_array([1, 2, 3, 4, 5, 6]))

  // filter
  let fil = LSeq::filter(s, fn(x) { x > 3 })
  inspect(LSeq::to_list(fil), content="@list.from_array([6, 5, 4])")

  // partition
  let (ev, od) = LSeq::partition(s, fn(x) { x % 2 == 0 })
  inspect(LSeq::to_list(ev), content="@list.from_array([6, 4, 2])")
  inspect(LSeq::to_list(od), content="@list.from_array([5, 3, 1])")

  // take_while / drop_while
  let tw = LSeq::take_while(s, fn(x) { x < 4 })
  inspect(LSeq::to_list(tw), content="@list.from_array([3, 2, 1])")
  let dw = LSeq::drop_while(s, fn(x) { x < 4 })
  inspect(LSeq::to_list(dw), content="@list.from_array([6, 5, 4])")

  // right variants
  let twr = LSeq::take_while_right(s, fn(x) { x > 3 })
  inspect(LSeq::to_list(twr), content="@list.from_array([6, 5, 4])")
  let dwr = LSeq::drop_while_right(s, fn(x) { x > 3 })
  inspect(LSeq::to_list(dwr), content="@list.from_array([3, 2, 1])")

  // span / break
  let (sp_l, sp_r) = LSeq::span(s, fn(x) { x < 4 })
  inspect(LSeq::to_list(sp_l), content="@list.from_array([3, 2, 1])")
  inspect(LSeq::to_list(sp_r), content="@list.from_array([6, 5, 4])")
  let (bk_l, bk_r) = LSeq::break_seq(s, fn(x) { x >= 4 })
  inspect(LSeq::to_list(bk_l), content="@list.from_array([3, 2, 1])")
  inspect(LSeq::to_list(bk_r), content="@list.from_array([6, 5, 4])")

  // concat_map
  let cm = LSeq::concat_map(LSeq::from_list(@list.from_array([1, 2, 3])), fn(
    x,
  ) {
    LSeq::from_list(@list.from_array([x, x]))
  })
  inspect(LSeq::to_list(cm), content="@list.from_array([3, 3, 2, 2, 1, 1])")
}

///|
test "measured index and split_at on large sequence" (_t : @test.T) {
  // build 1..500
  let mut s : Seq[Int] = Seq::empty()
  let mut i = 1
  while i <= 500 {
    s = Seq::snoc(s, i)
    i += 1
  }
  inspect(Seq::length(s), content="500")
  // index checks
  inspect(Seq::index(s, 0), content="1")
  inspect(Seq::index(s, 123), content="124")
  inspect(Seq::index(s, 499), content="500")

  // split_at middle
  let (l, r) = Seq::split_at(s, 250)
  inspect(Seq::length(l), content="250")
  inspect(Seq::length(r), content="250")
  inspect(Seq::index(l, 0), content="1")
  inspect(Seq::index(l, 249), content="250")
  inspect(Seq::index(r, 0), content="251")
  inspect(Seq::index(r, 249), content="500")
}

///|
test "scanr unfold and right spans/breaks" (_t : @test.T) {
  let s = Seq::from_list(@list.from_array([1, 2, 3]))
  // scanr (+) 0 [1,2,3] == [6,5,3,0] ; to_list 逆序为 [0,3,5,6]
  let sr = Seq::scanr(s, 0, fn(a, acc) { a + acc })
  inspect(Seq::to_list(sr), content="@list.from_array([0, 3, 5, 6])")

  // unfoldr: 3 -> [3,2,1] ; to_list 为 [1,2,3]
  let ur = Seq::unfoldr(
    fn(n) { if n > 0 { Some((n, n - 1)) } else { None } },
    3,
  )
  inspect(Seq::to_list(ur), content="@list.from_array([1, 2, 3])")

  // unfoldl: 0 -> [1,2,3] ; to_list 为 [3,2,1]
  let ul = Seq::unfoldl(
    fn(n) { if n < 3 { Some((n + 1, n + 1)) } else { None } },
    0,
  )
  inspect(Seq::to_list(ul), content="@list.from_array([1, 2, 3])")

  // span_right / break_right
  let s2 = Seq::from_list(@list.from_array([1, 2, 3, 4, 5, 6]))
  let (sp_l, sp_r) = Seq::span_right(s2, fn(x) { x > 3 })
  inspect(Seq::to_list(sp_l), content="@list.from_array([3, 2, 1])")
  inspect(Seq::to_list(sp_r), content="@list.from_array([6, 5, 4])")
  let (bk_l, bk_r) = Seq::break_right(s2, fn(x) { x > 3 })
  inspect(Seq::to_list(bk_l), content="@list.from_array([6, 5, 4, 3, 2, 1])")
  inspect(Seq::to_list(bk_r), content="@list.from_array([])")
}

///|
test "left-variant aliases: take_while_left / drop_while_left" (_t : @test.T) {
  let s = Seq::from_list(@list.from_array([1, 2, 3, 4, 5, 6]))
  let twl = Seq::take_while_left(s, fn(x) { x < 4 })
  inspect(Seq::to_list(twl), content="@list.from_array([3, 2, 1])")
  let dwl = Seq::drop_while_left(s, fn(x) { x < 4 })
  inspect(Seq::to_list(dwl), content="@list.from_array([6, 5, 4])")
}

///|
test "LSeq null on empty and non-empty" (_t : @test.T) {
  let e : LSeq[Int] = LSeq::empty()
  inspect(LSeq::null(e), content="true")
  let ne = LSeq::singleton(1)
  inspect(LSeq::null(ne), content="false")
}
