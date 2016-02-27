itertools
=========

Additional range primitives for iterations.
(inspired by Python)

[![Build Status](https://travis-ci.org/greenify/d-itertools.svg?branch=master)](https://travis-ci.org/greenify/d-itertools)

Methods
-------

### `pairwise`

```
Iterates over a range in pairs.
Allows non-filling end intervals:

[1,2,3].pairwise().array == [[1,2],[2,3]]

Params:
    r = Range from which the minimum will be selected
    pairLength = Pair size (default 2)

Returns: The minimum of the passed-in values.
```

### `product`

```
Lazily computes the Cartesian product of $(D r).
If the input is sorted, the product is in lexicographic order.
For example $(D"AB".product(2).array) returns $(D["AA", "AB", "BA", "BB"])

Params:
    r = RandomAccessRange or string as origin
    repeat = number of repetitions

Returns:
    Forward range with includes
```

### `combinations`

```
Lazily computes the all k-combinations of $(D r).
Imagine this as the product filtered for only strictly ordered items.

For example $(D"AB".combinations(2).array) returns $(D["AB"]).

Params:
    r = RandomAccessRange or string as origin
    k = number of combinations

Returns:
    Forward range which yields the k-combinations items
```

### `combinationsRepeat`

```
Lazily computes the all k-combinations of $(D r) with repetitions.
A k-combination with repetitions, or k-multicombination, or multisubset of size k from a set S is given by a sequence of k not necessarily distinct elements of S, where order is not taken into account.
Imagine this as the product filtered for only ordered items.

For example $(D"AB".combinationsRepeat(2).array) returns $(D["AA", "AB", "BB"]).

Params:
    r = RandomAccessRange or string as origin
    k = number of combinations

Returns:
    Forward range which yields the k-multicombinations items
```
