// The Computer Language Benchmarks Game
// http://benchmarksgame.alioth.debian.org/
//
// contributed by Zach Kelling
// modified by Roman Pletnev

var bignum = require('bignum');

function pad(i, last) {
    var res = i.toString(), count;
    if (count = 10 - res.length) {
        while (count--) last ? res += ' ' : res = 0 + res;
    }
    return res;
}

function calculatePi(N) {
    var i = 0,
        k = 0,
        k1 = 1,
        ns = 0,

        a = bignum(0),
        d = bignum(1),
        m = bignum(0),
        n = bignum(1),
        t = bignum(0),
        u = bignum(0);

    while (1) {
        k += 1;
        k1 += 2;
        t = n.shiftLeft(1);
        n = n.mul(k);
        a = a.add(t).mul(k1);
        d = d.mul(k1);

        if (a.cmp(n) >= 0) {
            m = n.mul(3).add(a);


            t = m.div(d);
            u = m.mod(d).add(n);

            if (d.cmp(u) > 0) {
                ns = ns * 10 + t.toNumber();
                i += 1;

                var last = i >= N;
                if (i % 10 === 0 || last) {
                    console.log(pad(ns, last) + '\t:' + i);
                    ns = 0;
                }

                if (last) break;

                a = a.sub(d.mul(t)).mul(10);
                n = n.mul(10);
            }
        }
    }
}

// Uses only one bigint division instead of two when checking a produced digit's validity.
calculatePi(process.argv[2] || 10);
