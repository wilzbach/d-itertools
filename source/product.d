import std.range: isRandomAccessRange, hasLength; //indexed
import std.traits: isNarrowString;

/**
Lazily computes the Cartesian product of $(D r).
If the input is sorted, the product is in lexicographic order.
For example $(D"AB".product(2).array) returns $(D["AA", "AB", "BA", "BB"])

Params:
    r = RandomAccessRange or string as origin
    repeat = number of repetitions

Returns:
    Forward range with includes
*/
auto product(Range)(Range r, size_t repeat=1)
if (isRandomAccessRange!Range && hasLength!Range)
in {
    assert(repeat >= 1, "Invalid repeat");
} body 
{
    static struct Product{
        private Range _r;
        private size_t[] _indices, _state;

        private size_t _repeat;
        private size_t _length;

        private bool _empty;

        this(Range r, size_t repeat)
        {
            _r = r;
            _length = r.length;
            _state = new size_t[repeat];
            _indices = [0];
        }

        void popFront(){
            if(empty){
                return;
            }
            _empty = true;
            _state = _state.dup;
            foreach_reverse (ref el; _state){
                ++el;
                // take the next digit
                if (el < _length){
                    _empty = false;
                    break;
                } else {
                    el = 0;
                }
            }
        }

        @property bool empty(){
            return _empty;
        }

        @property auto ref front(){
            import std.array: array;
            import std.range: indexed;
            return _r.indexed(_state).array;
        }
    }
    return Product(r, repeat);
}

unittest{
    import std.array: array;
    import std.algorithm: equal;
    import std.range: iota;
    import std.conv: to;
    assert(iota(2).product.array == [[0], [1]]);
    assert(iota(2).product(2).array == [[0, 0], [0, 1], [1, 0], [1, 1]]);
    assert("AB".array.product(2).array == (["AA", "AB", "BA", "BB"].to!(dchar[][])));
    assert("AB".array.product(3).array == ["AAA", "AAB", "ABA", "ABB", "BAA", "BAB", "BBA", "BBB"].to!(dchar[][]));
    assert("ABCD".array.product(2).array == ["AA","AB","AC","AD","BA","BB", "BC","BD", "CA", "CB", "CC","CD", "DA", "DB", "DC", "DD"].to!(dchar[][]));
    assert(iota(2).array.product.front == [0]);
}

