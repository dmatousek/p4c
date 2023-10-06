#include <core.p4>
#define V1MODEL_VERSION 20180101
#include <v1model.p4>

typedef bit<48> ethernet_addr_t;
typedef bit<32> ipv4_addr_t;
enum bit<16> EtherType {
    ETYPE_IPV4 = 16w0x800
}

header ethernet_t {
    ethernet_addr_t da;
    ethernet_addr_t sa;
    bit<16>         type;
}

header ipv4_t {
    bit<4>      version;
    bit<4>      ihl;
    bit<6>      dscp;
    bit<2>      ecn;
    bit<16>     total_len;
    bit<16>     identification;
    bit<1>      reserved;
    bit<1>      do_not_fragment;
    bit<1>      more_fragments;
    bit<13>     frag_offset;
    bit<8>      ttl;
    bit<8>      protocol;
    bit<16>     header_checksum;
    ipv4_addr_t src_addr;
    ipv4_addr_t dst_addr;
}

header ipv4_options_t {
    varbit<480> options;
}

struct headers_t {
    ethernet_t     mac;
    ipv4_options_t ip;
}

struct local_metadata_t {
}

parser v1model_parser(packet_in pkt, out headers_t hdrs, inout local_metadata_t local_meta, inout standard_metadata_t standard_meta) {
    @name("v1model_parser.ipv4") ipv4_t ipv4_0;
    @name("v1model_parser.byte_len") bit<32> byte_len_0;
    state start {
        pkt.extract<ethernet_t>(hdrs.mac);
        transition select(hdrs.mac.type) {
            EtherType.ETYPE_IPV4: parse_ipv4;
            default: accept;
        }
    }
    state parse_ipv4 {
        ipv4_0 = pkt.lookahead<ipv4_t>();
        byte_len_0 = (bit<32>)ipv4_0.ihl << 2;
        pkt.extract<ipv4_options_t>(hdrs.ip, byte_len_0 << 3);
        transition accept;
    }
}

control compute_ip_checksum(inout headers_t headers, inout local_metadata_t local_metadata) {
    apply {
    }
}

control verify_ip_checksum(inout headers_t headers, inout local_metadata_t local_metadata) {
    apply {
    }
}

control egress(inout headers_t headers, inout local_metadata_t local_metadata, inout standard_metadata_t standard_metadata) {
    apply {
    }
}

control ingress(inout headers_t headers, inout local_metadata_t local_metadata, inout standard_metadata_t standard_metadata) {
    apply {
    }
}

control deparser(packet_out packet, in headers_t headers) {
    apply {
    }
}

V1Switch<headers_t, local_metadata_t>(v1model_parser(), verify_ip_checksum(), ingress(), egress(), compute_ip_checksum(), deparser()) main;
