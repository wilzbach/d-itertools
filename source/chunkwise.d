#!/usr/bin/env rdmd

import std.range;
import std.array;
import std.algorithm;
import std.stdio;
import std.traits;

/**
Iterates over a range in splits.
Allows non-filling end intervals:

[1,2,3].chunkwise().array == [[1,2],[3]]

Params:
    r = Range from which the minimum will be selected
    pairLength = Chunk size (default 2)

Returns: The minimum of the passed-in values.
*/
auto chunkwise(Range)(Range r, int pairLength = 2)
if(isInputRange!Range)
in{
    assert(pairLength >= 1, "invalid pairLength");
}
body{
    static struct Chunkwise{
        private Range _input;
        private int _pairLength;
        private ElementType!(Range)[] _els;
        this (Range input, int pairLength)
        {
            this._input = input;
            this._pairLength = pairLength;
        }

        private void _popchunkwise(){
            // create new array -> make other mutable
            if(_input.empty){
                // soft catch in case we reached the end
                _els = null;
            }else{
                _els  = new ElementType!(Range)[](_pairLength);
                for (int i = 0; i < _pairLength; i++){
                    if(_input.empty){
                        _els.length = i;
                        break;
                    }
                    ElementType!Range el = _input.front;
                    _els[i] = el;
                    _input.popFront();
                }
            }
        }

        void popFront(){
            assert(!empty, "empty array");
            if(_els is null){
                // pop was never called before -> stuck before
                _popchunkwise();
            }
            _popchunkwise();
        }

        @property bool empty(){
            return _input.empty && _els is null;
        }

        @property auto ref front(){
            assert(!empty, "r is already empty"); 
            if (_els is null){
                _popchunkwise();
            }
            return _els;
        }
    }
    return Chunkwise(r, pairLength);
}

///
unittest{
    assert([0,1,2,3,4,5].chunkwise.array == [[0, 1], [2, 3], [4, 5]]);
    assert(iota(5).chunkwise(2).front == [0,1]);
}

unittest{
    assert([0,1,2,3,4,5].chunkwise(3).array == [[0, 1, 2], [3, 4, 5]]);
    assert(iota(2).chunkwise(2).front == [0,1]);
    assert(iota(3).chunkwise(2).array == [[0,1],[2]]);
    assert(iota(2).chunkwise(3).front == [0,1]);
    int[] d;
    assert(d.chunkwise.empty);
    auto e = iota(5).chunkwise(2);
    e.popFront;
    assert(e.array == [[2,3],[4]]);
}

unittest{
    // test chunkwise2 step by step
    auto a = [0,1,2,3,4,5].chunkwise;
    assert(a.front == [0,1]); 
    a.popFront();
    assert(a.front == [2,3]); 
    a.popFront();
    assert(a.front == [4,5]); 
    a.popFront();
    assert(a.empty);
}

unittest{
    // test chunkwise3 step by step
    auto a = [0,1,2,3].chunkwise(3);
    assert(a.front == [0,1,2]); 
    a.popFront();
    assert(a.front == [3]); 
    a.popFront();
    assert(a.empty);
}
