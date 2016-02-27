/**
This range iterates over fixed-sized pairs of size $(D chunkSize) of a
$(D source) range. $(D Source) must be a forward range. $(D chunkSize) must be
greater than zero.

$(D[1,2,3].pairwise().array == [[1,2],[2,3]])

Params:
    r = Range from which the minimum will be selected
    pairLength = Pair size (default 2)

Returns: Input range with the pairs
*/

import std.range;
import std.algorithm;
import std.stdio;

struct Pairwise(Source)
    if (isForwardRange!Source)
{
    /// Standard constructor
    this(Source source, size_t chunkSize)
    {
        assert(chunkSize != 0, "Cannot create a Chunk with an empty chunkSize");
        _source = source;
        _chunkSize = chunkSize;
        _endSource = source.save;
        
        // if we kick the elements out of memory, gc will kick in
        static if (hasLength!Source){
            if(_endSource.length > _chunkSize){ 
                _endSource.popFrontN(chunkSize - 1);
            }else{
                // still remove some elements that .empty works
                _endSource.popFrontN(_endSource.length - 1);
            }
        }else{
            _endSource.popFrontN(chunkSize - 1);
        }
    }
    
    /// Forward range primitives. Always present.
    @property auto front()
    {
        assert(!_source.empty);
        return _source.save.take(_chunkSize);
    }

    /// Ditto
    void popFront()
    {
        assert(!_source.empty);
        _source.popFront;
        if(!_endSource.empty){
            _endSource.popFront;
        }
    }

    static if (!isInfinite!Source)
        /// Ditto
        @property bool empty()
        {
            // CHANGED
            return _endSource.empty;
        }
    else
        // undocumented
        enum empty = false;

    /// Ditto
    @property typeof(this) save()
    {
        return typeof(this)(_source.save, _chunkSize);
    }

    static if (hasLength!Source)
    {
        /// Length. Only if $(D hasLength!Source) is $(D true)
        @property size_t length()
        {
            // Note: _source.length + _chunkSize may actually overflow.
            // We cast to ulong to mitigate the problem on x86 machines.
            // For x64 machines, we just suppose we'll never overflow.
            // The "safe" code would require either an extra branch, or a
            //   modulo operation, which is too expensive for such a rare case
            // CHANGED
            if(_chunkSize > _source.length){
                return 1;
            }else{
                return cast(size_t)((cast(ulong)(_source.length) - _chunkSize + 1));
            }
        }
        //Note: No point in defining opDollar here without slicing.
        //opDollar is defined below in the hasSlicing!Source section
    }

    static if (hasSlicing!Source)
    {
        //Used for various purposes
        private enum hasSliceToEnd = is(typeof(Source.init[_chunkSize .. $]) == Source);

        /**
        Indexing and slicing operations. Provided only if
        $(D hasSlicing!Source) is $(D true).
         */
        auto opIndex(size_t index)
        {
            // CHANGED
            immutable start = max(0, index);
            immutable end   = start + _chunkSize;

            static if (isInfinite!Source)
                return _source[start .. end];
            else
            {
                import std.algorithm : min;
                immutable len = _source.length;
                assert(start < len, "chunks index out of bounds");
                return _source[start .. min(end, len)];
            }
        }

        /// Ditto
        static if (hasLength!Source)
            typeof(this) opSlice(size_t lower, size_t upper)
            {
                import std.algorithm : min;
                assert(lower <= upper && upper <= length, "chunks slicing index out of bounds");
                immutable len = _source.length;
                // CHANGED
                return pairwise(_source[min(lower, len) .. min(upper + _chunkSize, len)], _chunkSize);
                //return chunks(_source[min(lower * _chunkSize, len) .. min(upper * _chunkSize, len)], _chunkSize);
            }
        else static if (hasSliceToEnd)
            //For slicing an infinite chunk, we need to slice the source to the end.
            typeof(takeExactly(this, 0)) opSlice(size_t lower, size_t upper)
            {
                assert(lower <= upper, "chunks slicing index out of bounds");
                // CHANGED
                return pairwise(_source[lower .. $], _chunkSize).takeExactly(upper - lower);
                //return chunks(_source[lower * _chunkSize .. $], _chunkSize).takeExactly(upper - lower);
            }

        static if (isInfinite!Source)
        {
            static if (hasSliceToEnd)
            {
                private static struct DollarToken{}
                DollarToken opDollar()
                {
                    return DollarToken();
                }
                //Slice to dollar
                typeof(this) opSlice(size_t lower, DollarToken)
                {
                    // CHANGED
                    return typeof(this)(_source[lower .. $], _chunkSize);
                    //return typeof(this)(_source[lower * _chunkSize .. $], _chunkSize);
                }
            }
        }
        else
        {
            //Dollar token carries a static type, with no extra information.
            //It can lazily transform into _source.length on algorithmic
            //operations such as : chunks[$/2, $-1];
            private static struct DollarToken
            {
                Pairwise!Source* mom;
                @property size_t momLength()
                {
                    return mom.length;
                }
                alias momLength this;
            }
            DollarToken opDollar()
            {
                return DollarToken(&this);
            }

            //Slice overloads optimized for using dollar. Without this, to slice to end, we would...
            //1. Evaluate chunks.length
            //2. Multiply by _chunksSize
            //3. To finally just compare it (with min) to the original length of source (!)
            //These overloads avoid that.
            typeof(this) opSlice(DollarToken, DollarToken)
            {
                static if (hasSliceToEnd)
                    return pairwise(_source[$ .. $], _chunkSize);
                else
                {
                    immutable len = _source.length;
                    return pairwise(_source[len .. len], _chunkSize);
                }
            }
            typeof(this) opSlice(size_t lower, DollarToken)
            {
                import std.algorithm : min;
                assert(lower <= length, "chunks slicing index out of bounds");
                static if (hasSliceToEnd)
                    // CHANGED
                    return pairwise(_source[min(lower, _source.length) .. $], _chunkSize);
                    //return chunks(_source[min(lower * _chunkSize, _source.length) .. $], _chunkSize);
                else
                {
                    immutable len = _source.length;
                    // CHANGED
                    return pairwise(_source[min(lower, len) .. len], _chunkSize);
                    //return chunks(_source[min(lower * _chunkSize, len) .. len], _chunkSize);
                }
            }
            typeof(this) opSlice(DollarToken, size_t upper)
            {
                assert(upper == length, "chunks slicing index out of bounds");
                return this[$ .. $];
            }
        }
    }

    //Bidirectional range primitives
    static if (hasSlicing!Source && hasLength!Source)
    {
        /**
        Bidirectional range primitives. Provided only if both
        $(D hasSlicing!Source) and $(D hasLength!Source) are $(D true).
         */
        @property auto back()
        {
            assert(!empty, "back called on empty chunks");
            immutable len = _source.length;
            immutable start = max(0, len - _chunkSize);
            return _source[start .. $];
        }

        /// Ditto
        void popBack()
        {
            assert(!empty, "popBack() called on empty chunks");
            immutable end = (_source.length - 1) / _chunkSize * _chunkSize;
            // CHANGED
            _source.popBack;
            _endSource.popBack;
            //_source = _source[0 .. end];
        }
    }

private:
    Source _source, _endSource;
    size_t _chunkSize;
}

/// Ditto
Pairwise!Source pairwise(Source)(Source source, size_t chunkSize = 2)
// CHANGED to default to 2
if (isForwardRange!Source)
{
    return typeof(return)(source, chunkSize);
}

import std.array;
import std.range: iota;

unittest{
    assert([0,1,2].pairwise.array == [[0, 1], [1,2]]);
    assert(iota(5).pairwise(2).front.equal([0,1]));
}

unittest{
    assert([0,1,2,3].pairwise(3).array == [[0, 1, 2], [1, 2, 3]]);
    assert(iota(2).pairwise(2).front.equal([0,1]));
    assert(iota(3).pairwise(2).map!"a.array".array == [[0,1],[1,2]]);
    int[] d;
    assert(d.pairwise.empty);
    auto e = iota(5).pairwise;
    e.popFront;
    assert(e.save.map!"a.array".array == [[1,2], [2,3],[3,4]]);
    assert(e.map!"a.array".array == [[1,2], [2,3],[3,4]]);
}

unittest{
    // test pairwise2 step by step
    auto a = [0,1,2,3].pairwise;
    assert(a.front == [0,1]); 
    a.popFront();
    assert(a.front == [1,2]); 
    a.popFront();
    assert(a.front == [2,3]); 
    a.popFront();
    assert(a.empty);
}

unittest{
    import std.conv: to;
    assert(iota(3).pairwise(3).array.to!string == "[[0, 1, 2]]");
    assert(iota(3).pairwise(4).array.to!string == "[[0, 1, 2]]");
    assert(iota(3).pairwise(4)[0..$].to!string == "[[0, 1, 2]]");
    assert(iota(3).pairwise(2)[1..$].to!string == "[[1, 2]]");
    assert(iota(3).pairwise(4)[0].equal([0, 1, 2]));
    assert(iota(1, 5).pairwise(2)[0..1].to!string == "[[1, 2], [2, 3]]");
    assert(iota(1, 4).pairwise(1).map!"a.array".array == [[1],[2],[3]]);
    assert(iota(1, 4).pairwise(3).map!"a.array".array == [[1,2,3]]);

    // length
    assert(iota(3).pairwise(3).length == 1);
    assert(iota(3).pairwise(2).length == 2);
    assert(iota(3).pairwise(1).length == 3);
}

unittest{
    // other ranges

    //InfiniteRange w/o RA
    auto fibsByPairs = recurrence!"a[n-1] + a[n-2]"(1, 1).pairwise(2);
    assert(equal!`equal(a, b)`(fibsByPairs.take(2), [[ 1,  1], [ 1,  2]]));

    //InfiniteRange w/ RA and slicing
    auto odds = sequence!("a[0] + n * a[1]")(1, 2);
    auto oddsByPairs = odds.pairwise(2);
    assert(equal!`equal(a, b)`(oddsByPairs.take(2), [[ 1,  3], [ 3,  5]]));

    //Requires phobos#991 for Sequence to have slice to end
    static assert(hasSlicing!(typeof(odds)));
    assert(equal!`equal(a, b)`(oddsByPairs[3 .. 5],         [[7, 9], [9, 11]]));
    assert(equal!`equal(a, b)`(oddsByPairs[3 .. $].take(2), [[7, 9], [9, 11]]));

}

unittest{
    // reverse
    auto e = iota(3).pairwise(2);
    assert(e.back.equal([1, 2]));
    e.popBack;
    assert(e.back.equal([0, 1]));
    e.popBack;
    assert(e.empty);
}

unittest{
    // test pairwise3 step by step
    auto a = [0,1,2,3].pairwise(3);
    assert(a.front == [0,1,2]); 
    a.popFront();
    assert(a.front == [1,2,3]); 
    a.popFront();
    assert(a.empty);
}
