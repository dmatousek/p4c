#include <core.p4>

header H {
    bit<16> a;
}

struct metadata {
}

struct Headers {
    H h;
}

parser p(packet_in packet, out Headers hdr) {
    state parse {
        hdr.h.a = 16w1;
        transition accept;
    }
    state start {
        packet.extract<H>(hdr.h);
        transition select(hdr.h.a) {
            16w0x0: parse;
            16w0x1: parse;
            16w0x2 &&& 16w0xfffe: parse;
            16w0x4: parse;
            default: accept;
        }
    }
}

parser Parser(packet_in b, out Headers hdr);
package top(Parser p);
top(p()) main;

