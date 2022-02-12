#include <core.p4>
#define V1MODEL_VERSION 20180101
#include <v1model.p4>

header ethernet_t {
    bit<48> dst_addr;
    bit<48> src_addr;
    bit<16> eth_type;
}

header H {
    bit<8> a;
}

header I {
    bit<1> id;
    bit<7> padding;
}

struct Headers {
    ethernet_t eth_hdr;
    H[2]       h;
    I          i;
}

struct Meta {
}

parser p(packet_in pkt, out Headers hdr, inout Meta m, inout standard_metadata_t sm) {
    state start {
        pkt.extract<ethernet_t>(hdr.eth_hdr);
        pkt.extract<H>(hdr.h[32w0]);
        pkt.extract<H>(hdr.h[32w1]);
        pkt.extract<I>(hdr.i);
        transition accept;
    }
}

control ingress(inout Headers h, inout Meta m, inout standard_metadata_t sm) {
    @name("ingress.tmp_0") bit<1> tmp_0;
    @hidden action gauntlet_index_7bmv2l51() {
        h.h[1w0].a = 8w1;
    }
    @hidden action gauntlet_index_7bmv2l51_0() {
        h.h[1w1].a = 8w1;
    }
    @hidden action gauntlet_index_7bmv2l51_1() {
        tmp_0 = h.i.id;
        h.i.id = 1w0;
    }
    @hidden table tbl_gauntlet_index_7bmv2l51 {
        actions = {
            gauntlet_index_7bmv2l51_1();
        }
        const default_action = gauntlet_index_7bmv2l51_1();
    }
    @hidden table tbl_gauntlet_index_7bmv2l51_0 {
        actions = {
            gauntlet_index_7bmv2l51();
        }
        const default_action = gauntlet_index_7bmv2l51();
    }
    @hidden table tbl_gauntlet_index_7bmv2l51_1 {
        actions = {
            gauntlet_index_7bmv2l51_0();
        }
        const default_action = gauntlet_index_7bmv2l51_0();
    }
    apply {
        tbl_gauntlet_index_7bmv2l51.apply();
        if (tmp_0 == 1w0) {
            tbl_gauntlet_index_7bmv2l51_0.apply();
        } else if (tmp_0 == 1w1) {
            tbl_gauntlet_index_7bmv2l51_1.apply();
        }
    }
}

control vrfy(inout Headers h, inout Meta m) {
    apply {
    }
}

control update(inout Headers h, inout Meta m) {
    apply {
    }
}

control egress(inout Headers h, inout Meta m, inout standard_metadata_t sm) {
    apply {
    }
}

control deparser(packet_out pkt, in Headers h) {
    apply {
        pkt.emit<ethernet_t>(h.eth_hdr);
        pkt.emit<H>(h.h[0]);
        pkt.emit<H>(h.h[1]);
        pkt.emit<I>(h.i);
    }
}

V1Switch<Headers, Meta>(p(), vrfy(), ingress(), egress(), update(), deparser()) main;

