import std.range: isRandomAccessRange, hasLength, ElementType; //indexed

size_t binomial(size_t n, size_t k) pure nothrow @safe @nogc
in {
    assert(n > 0, "binomial: n must be > 0.");
} body {
    if (k < 0 || k > n)
        return 0;
    if (k == n)
        return 1;
    if (k > (n / 2))
        k = n - k;
    size_t result = 1;
    for (size_t i=1, m=n; i<=k; i++, m--)
        result = result * m/i;
    return result;
}

enum CombiType{
    Product, Combination, CombinationRepeat
}

auto combinatorial(CombiType combiType=Product, Range)(Range r, size_t repeat=1)
if (isRandomAccessRange!Range && hasLength!Range)
in {
    assert(repeat >= 1, "Invalid repeat");
} body 
{
    import std.array: array;
    import std.range: indexed;
    static struct Combinatorial{
        ElementType!Range[] front;
        private Range _r;
        private size_t[] _state;

        private size_t _repeat, _length;
        private size_t _max_states, _pos;
        private bool _lengthComputed;

        bool empty;

        //this(Range r, size_t repeat) pure nothrow @safe
        this(Range r, size_t repeat) 
        {
            _r = r;
            _length = r.length;
            _repeat = repeat;

            // set initial state
            _max_states = length;
            if(_length > 0 && _max_states > 0){
                _state = new size_t[repeat];
                static if(combiType == CombiType.Combination){
                    // skip first duplicate
                    if(_length > 1 && _repeat > 1){
                        import std.range: iota;
                        _state = iota(repeat).array;
                    }
                }
                front = _r.indexed(_state).array;
            }else{
                empty = true;
            }
        }

        @property typeof(this) save()
        {
            import std.stdio;
            auto c = typeof(this)(_r, _repeat);
            c._state = _state.dup;
            c._pos = _pos;
            c.empty = empty;
            return c;
        }

        private void _getNextState(){
            foreach_reverse (i, ref el; _state){
                ++el;
                if (el < _length){
                    break;
                } else {
                    el = 0;
                }
            }
        }

        //void popFront() pure nothrow @safe {
        void popFront() {
            import std.stdio;
            if(empty) return;
            // check whether we have reached the end
            _pos++;
            if(_pos == _max_states){
                empty = true;
                return;
            }
            static if(combiType == CombiType.Combination){
                //do _getNextState();  while(!_state.isStrictlySorted);
                size_t i = _repeat - 1;
	            // go to next settable item (not at end state)
	            while (_state[i] == _length - _repeat + i) {
	                i--;
	            }
	            _state[i] = _state[i] + 1;
	            for (size_t j = i + 1; j < _repeat; j++) {
	                _state[j] = _state[i] + j - i;
	            }
            }else static if(combiType == CombiType.CombinationRepeat){
                //do _getNextState();  while(!_state.isSorted);
                size_t i = _repeat - 1;
	            // go to next settable item (not at end state)
	            while (_state[i] == _length - 1) {
	                i--;
	            }
                _state[i] = _state[i] + 1;
                if(i == 0){
                    // reset all bits and start at the beginning
                    foreach_reverse (ref el; _state){
                        el = _state[i];
                    }
                }
            }else static if(combiType == CombiType.Product){
                foreach_reverse (i, ref el; _state){
                    ++el;
                    if (el < _length){
                        break;
                    } else {
                        el = 0;
                    }
                }
            }
            front = _r.indexed(_state).array;
        }

        @property size_t length() pure nothrow @nogc {
            if(!_lengthComputed){
                if(_length == 0){
                    _max_states = 0;
                }else{
                    static if(combiType == CombiType.Combination){
                        _max_states = binomial(_length, _repeat);
                    }else static if(combiType == CombiType.CombinationRepeat){
                        _max_states = binomial(_length + _repeat  - 1, _repeat);
                    }else static if(combiType == CombiType.Product){
                        import std.math: pow;
                        _max_states = pow(_length, _repeat);
                    }
                }
                _lengthComputed = true;
            }
            return _max_states;
        }
    }
    return Combinatorial(r, repeat);
}

unittest{
import std.array: array;
import std.range: iota;
assert(iota(3).product(2).array == [[0, 0], [0, 1], [0, 2], [1, 0], [1, 1], [1, 2], [2, 0], [2, 1], [2, 2]]);
assert(iota(3).combinations(2).array == [[0, 1], [0, 2], [1, 2]]);
assert(iota(3).combinationsRepeat(2).array == [[0, 0], [0, 1], [0, 2], [1, 1], [1, 2], [2, 2]]);
}

/**
Lazily computes the Cartesian product of $(D r).
If the input is sorted, the product is in lexicographic order.
For example $(D"AB".product(2).array) returns $(D["AA", "AB", "BA", "BB"])

Params:
    r = RandomAccessRange or string as origin
    repeat = number of repetitions

Returns:
    Forward range which yields the product items
*/
auto product(Range)(Range r, size_t repeat=1)
if (isRandomAccessRange!Range && hasLength!Range)
in {
    assert(repeat >= 1, "Invalid repeat");
}body{
    return combinatorial!(CombiType.Product)(r,repeat);
}

unittest{
    import std.array: array;
    import std.algorithm: equal;
    import std.range: iota, dropOne;
    import std.conv: to;
    import std.stdio;
    assert(iota(0).product.array == []);
    assert(iota(2).product.array == [[0], [1]]);
    assert(iota(2).product(2).array == [[0, 0], [0, 1], [1, 0], [1, 1]]);
    assert("AB".array.product(2).array == (["AA", "AB", "BA", "BB"].to!(dchar[][])));
    assert("AB".array.product(3).array == ["AAA", "AAB", "ABA", "ABB", "BAA", "BAB", "BBA", "BBB"].to!(dchar[][]));
    assert("ABCD".array.product(2).array == ["AA","AB","AC","AD","BA","BB", "BC","BD", "CA", "CB", "CC","CD", "DA", "DB", "DC", "DD"].to!(dchar[][]));
    assert(iota(2).array.product.front == [0]);

    // copy able
    auto a = iota(2).product;
    assert(a.front == [0]);
    assert(a.save.dropOne.front == [1]);
    assert(a.front == [0]);
}

/**
Lazily computes the all k-combinations of $(D r).
Imagine this as the product filtered for only strictly ordered items.

For example $(D"AB".combinations(2).array) returns $(D["AB"]).

Params:
    r = RandomAccessRange or string as origin
    k = number of combinations

Returns:
    Forward range which yields the k-combinations items
*/
auto combinations(Range)(Range r, size_t k=1)
if (isRandomAccessRange!Range && hasLength!Range)
in {
    assert(k >= 1, "Invalid repeat");
}body{
    return combinatorial!(CombiType.Combination)(r,k);
}

unittest{
    import std.array: array;
    import std.algorithm: equal;
    import std.range: iota, dropOne;
    import std.conv: to;
    import std.stdio;
    assert(iota(0).combinations.array == []);
    assert(iota(2).combinations.array == [[0], [1]]);
    assert("AB".array.combinations(2).array == (["AB"].to!(dchar[][])));
    assert("ABC".array.combinations(2).array == ["AB", "AC","BC"].to!(dchar[][]));
    assert("ABCD".array.combinations(2).array == ["AB","AC","AD","BC","BD", "CD"].to!(dchar[][]));
    assert(iota(2).array.combinations.front == [0]);
    
    // copy able
    auto a = iota(2).combinations;
    assert(a.front == [0]);
    assert(a.save.dropOne.front == [1]);
    assert(a.front == [0]);

    // test larger combis
    assert(iota(5).array.combinations(3).array == [[0, 1, 2], [0, 1, 3], [0, 1, 4], [0, 2, 3], [0, 2, 4], [0, 3, 4], [1, 2, 3], [1, 2, 4], [1, 3, 4], [2, 3, 4]]);
    assert(iota(4).array.combinations(3).array == [[0, 1, 2], [0, 1, 3], [0, 2, 3], [1, 2, 3]]);
    assert(iota(3).array.combinations(3).array == [[0, 1, 2]]);
    assert(iota(2).array.combinations(3).array == []);
    assert(iota(1).array.combinations(3).array == []);
    assert(iota(3).array.combinations(2).array == [[0, 1], [0, 2], [1, 2]]);
    assert(iota(2).array.combinations(2).array == [[0, 1]]);
    assert(iota(1).array.combinations(2).array == []);
    assert(iota(1).array.combinations(1).array == [[0]]);
}

/**
Lazily computes the all k-combinations of $(D r) with repetitions.
A k-combination with repetitions, or k-multicombination, or multisubset of size k from a set S is given by a sequence of k not necessarily distinct elements of S, where order is not taken into account.
Imagine this as the product filtered for only ordered items.

For example $(D"AB".combinationsRepeat(2).array) returns $(D["AA", "AB", "BB"]).

Params:
    r = RandomAccessRange or string as origin
    k = number of combinations

Returns:
    Forward range which yields the k-multicombinations items
*/
auto combinationsRepeat(Range)(Range r, size_t k=1)
if (isRandomAccessRange!Range && hasLength!Range)
in {
    assert(k >= 1, "Invalid k");
}body{
    return combinatorial!(CombiType.CombinationRepeat)(r, k);
}

unittest{
    import std.array: array;
    import std.algorithm: equal;
    import std.range: iota, dropOne;
    import std.conv: to;
    import std.stdio;
    assert(iota(0).combinationsRepeat.array == []);
    assert(iota(2).combinationsRepeat.array == [[0], [1]]);
    assert(iota(2).combinationsRepeat(2).array == [[0, 0], [0, 1], [1, 1]]);
    assert("AB".array.combinationsRepeat(2).array == (["AA", "AB",  "BB"].to!(dchar[][])));
    assert("AB".array.combinationsRepeat(3).array == ["AAA", "AAB", "ABB","BBB"].to!(dchar[][]));
    assert("ABCD".array.combinationsRepeat(2).array == ["AA","AB","AC","AD","BB", "BC","BD", "CC","CD", "DD"].to!(dchar[][]));
    assert(iota(2).array.combinationsRepeat.front == [0]);

    // copy able
    auto a = iota(2).combinationsRepeat;
    assert(a.front == [0]);
    assert(a.save.dropOne.front == [1]);
    assert(a.front == [0]);
}
