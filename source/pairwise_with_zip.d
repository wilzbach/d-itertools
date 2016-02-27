import std.array;
import std.range;
import std.stdio;


auto pairwise(Range)(Range r, int pairLength = 2){
    Range[] bs = new Range[](2);
    bs[0] = r;
    Range b = r.save;
    b.popFront;
    bs[1] = b;
    //return zip(r,b);
    return zip(r,b);
}


unittest{
    // zip(arr,arr.save.dropOne).writeln;
    import std.algorithm;
    import std.conv;
    import std.typecons;
    assert([1,2,3].pairwise.array == [tuple(1, 2), tuple(2, 3)]);
}
