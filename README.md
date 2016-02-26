itertools
=========

Additional range primitives for iterations.
(inspired by Python)

[![Build Status](https://travis-ci.org/greenify/d-itertools.svg?branch=master)](https://travis-ci.org/greenify/d-itertools)

Methods
-------

### `pairwise`

Iterates over a range in pairs.
Allows non-filling end intervals:

[1,2,3].pairwise().array == [[1,2],[2,3]]

Params:
    r = Range from which the minimum will be selected
    pairLength = Pair size (default 2)

Returns: The minimum of the passed-in values.

### `splitwise`

Iterates over a range in splits.
Allows non-filling end intervals:

[1,2,3].splitwise().array == [[1,2],[3]]

Params:
    r = Range from which the minimum will be selected
    pairLength = 

Returns: The minimum of the passed-in values.


TODO
------

- Decide whether it is ok to have _transient_ iterators
- use a better method instead of the circular buffer with `dup` for pairwise
