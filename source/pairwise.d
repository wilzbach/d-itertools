#!/usr/bin/env rdmd

import std.range;
import std.array;
import std.algorithm;
import std.stdio;
import std.traits;

/**
Iterates over a range in pairs.
Allows non-filling end intervals:

[1,2,3].pairwise().array == [[1,2],[2,3]]

Params:
    r = Range from which the minimum will be selected
    pairLength = Pair size (default 2)

Returns: The minimum of the passed-in values.
*/
auto pairwise(Range)(Range r, int pairLength = 2)
if(isInputRange!Range)
in{
    assert(pairLength >= 1, "invalid pairLength");
}
body{
    import std.container;
    static struct Pairwise{
        private Range _input;
        private int _pairLength;
        private ElementType!(Range)[] _els;
        private bool buffered;
        private int _bufferPos;
        this (Range input, int pairLength)
        {
            this._input = input;
            this._pairLength = pairLength;
        }

        private void _insertElement(){
            _els = _els.dup;
            _els[_bufferPos] = _input.front;
            _input.popFront();
            _bufferPos = (_bufferPos + 1) % _pairLength;
        }

        private void _popPairwise(){
            if (!buffered){
                // preload buffer
                _els = new ElementType!(Range)[](_pairLength);
                for (int i=0; i < _pairLength;i++){
                    if(_input.empty){
                        // shrink buffer once
                        _els = _els.dup;
                        _els.length = i;
                        break;
                    }
                    _insertElement();
                }
                buffered = true;
            }else if (!_input.empty){
                _insertElement();
            }
            // TODO: create new array -> make other mutable
        }

        void popFront(){
            assert(!empty, "empty array");
            if (!buffered){
                // pop was never called before -> stuck before
                _popPairwise();
            }
            if(!_input.empty){
                _popPairwise();
            } else {
                // reached end of buffer
                _els.length = 0;
            }
        }

        @property bool empty(){
            return _input.empty && _els.empty;
        }

        @property auto ref front(){
            assert(!empty, "r is already empty"); 
            if (!buffered){
                _popPairwise();
            }
            // TODO needs array concat and dup for a non transient method
            if(_bufferPos != 0){
                return _els[_bufferPos..$] ~ _els[0.._bufferPos];
            }else{
                return _els;
            }
        }
    }
    return Pairwise(r, pairLength);
}

///
unittest{
    assert([0,1,2].pairwise.array == [[0, 1], [1,2]]);
    assert(iota(5).pairwise(2).front == [0,1]);
}

unittest{
    assert([0,1,2,3].pairwise(3).array == [[0, 1, 2], [1, 2, 3]]);
    assert(iota(2).pairwise(2).front == [0,1]);
    assert(iota(3).pairwise(2).array == [[0,1],[1,2]]);
    assert(iota(2).pairwise(3).front == [0,1]);
    int[] d;
    assert(d.pairwise.empty);
    auto e = iota(5).pairwise(2);
    e.popFront;
    assert(e.array == [[1,2], [2,3],[3,4]]);
    assert(e.array == [[1,2], [2,3],[3,4]]);

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
    // test pairwise3 step by step
    auto a = [0,1,2,3].pairwise(3);
    assert(a.front == [0,1,2]); 
    a.popFront();
    assert(a.front == [1,2,3]); 
    a.popFront();
    assert(a.empty);
}
