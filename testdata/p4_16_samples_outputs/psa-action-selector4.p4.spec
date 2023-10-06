

struct ethernet_t {
	bit<48> dstAddr
	bit<48> srcAddr
	bit<16> etherType
}

struct psa_ingress_output_metadata_t {
	bit<8> class_of_service
	bit<8> clone
	bit<16> clone_session_id
	bit<8> drop
	bit<8> resubmit
	bit<32> multicast_group
	bit<32> egress_port
}

struct psa_egress_output_metadata_t {
	bit<8> clone
	bit<16> clone_session_id
	bit<8> drop
}

struct psa_egress_deparser_input_metadata_t {
	bit<32> egress_port
}

struct a1_arg_t {
	bit<48> param
}

struct a2_arg_t {
	bit<16> param
}

struct tbl_set_group_id_arg_t {
	bit<32> group_id
}

struct tbl_set_member_id_arg_t {
	bit<32> member_id
}

struct user_meta_t {
	bit<32> psa_ingress_input_metadata_ingress_port
	bit<8> psa_ingress_output_metadata_drop
	bit<32> psa_ingress_output_metadata_egress_port
	bit<16> local_metadata_data
	bit<32> Ingress_as_group_id
	bit<32> Ingress_as_member_id
}
metadata instanceof user_meta_t

header ethernet instanceof ethernet_t

action NoAction args none {
	return
}

action a1 args instanceof a1_arg_t {
	mov h.ethernet.dstAddr t.param
	return
}

action a2 args instanceof a2_arg_t {
	mov h.ethernet.etherType t.param
	return
}

action tbl_set_group_id args instanceof tbl_set_group_id_arg_t {
	mov m.Ingress_as_group_id t.group_id
	return
}

action tbl_set_member_id args instanceof tbl_set_member_id_arg_t {
	mov m.Ingress_as_member_id t.member_id
	return
}

table tbl {
	key {
		h.ethernet.srcAddr exact
	}
	actions {
		tbl_set_group_id
		tbl_set_member_id
		NoAction
	}
	default_action NoAction args none 
	size 0x10000
}


table as {
	key {
		m.Ingress_as_member_id exact
	}
	actions {
		NoAction
		a1
		a2
	}
	default_action NoAction args none 
	size 0x10000
}


table foo {
	actions {
		NoAction
	}
	default_action NoAction args none 
	size 0x10000
}


selector as_sel {
	group_id m.Ingress_as_group_id
	selector {
		m.local_metadata_data
	}
	member_id m.Ingress_as_member_id
	n_groups_max 0x400
	n_members_per_group_max 0x10000
}

apply {
	rx m.psa_ingress_input_metadata_ingress_port
	mov m.psa_ingress_output_metadata_drop 0x1
	extract h.ethernet
	mov m.Ingress_as_member_id 0x0
	mov m.Ingress_as_group_id 0xFFFFFFFF
	table tbl
	jmpnh LABEL_END
	jmpeq LABEL_FALSE_0 m.Ingress_as_group_id 0xFFFFFFFF
	table as_sel
	jmpnh LABEL_END
	table as
	jmpnh LABEL_END
	table foo
	jmp LABEL_END
	jmp LABEL_END
	LABEL_FALSE_0 :	table as
	jmpnh LABEL_END
	table foo
	LABEL_END :	mov m.Ingress_as_member_id 0x0
	mov m.Ingress_as_group_id 0xFFFFFFFF
	table tbl
	jmpnh LABEL_END_4
	jmpeq LABEL_FALSE_5 m.Ingress_as_group_id 0xFFFFFFFF
	table as_sel
	jmpnh LABEL_END_4
	table as
	jmpnh LABEL_END_4
	table foo
	jmp LABEL_END_4
	jmp LABEL_END_4
	LABEL_FALSE_5 :	table as
	jmpnh LABEL_END_4
	table foo
	LABEL_END_4 :	mov m.Ingress_as_member_id 0x0
	mov m.Ingress_as_group_id 0xFFFFFFFF
	table tbl
	jmpnh LABEL_FALSE_9
	jmpeq LABEL_FALSE_10 m.Ingress_as_group_id 0xFFFFFFFF
	table as_sel
	jmpnh LABEL_FALSE_11
	table as
	jmpnh LABEL_FALSE_12
	jmp LABEL_END_9
	LABEL_FALSE_12 :	table foo
	jmp LABEL_END_9
	LABEL_FALSE_11 :	table foo
	jmp LABEL_END_9
	LABEL_FALSE_10 :	table as
	jmpnh LABEL_FALSE_13
	jmp LABEL_END_9
	LABEL_FALSE_13 :	table foo
	jmp LABEL_END_9
	LABEL_FALSE_9 :	table foo
	LABEL_END_9 :	mov m.Ingress_as_member_id 0x0
	mov m.Ingress_as_group_id 0xFFFFFFFF
	table tbl
	jmpnh LABEL_FALSE_14
	jmpeq LABEL_FALSE_15 m.Ingress_as_group_id 0xFFFFFFFF
	table as_sel
	jmpnh LABEL_FALSE_16
	table as
	jmpnh LABEL_FALSE_17
	jmp LABEL_END_14
	LABEL_FALSE_17 :	table foo
	jmp LABEL_END_14
	LABEL_FALSE_16 :	table foo
	jmp LABEL_END_14
	LABEL_FALSE_15 :	table as
	jmpnh LABEL_FALSE_18
	jmp LABEL_END_14
	LABEL_FALSE_18 :	table foo
	jmp LABEL_END_14
	LABEL_FALSE_14 :	table foo
	LABEL_END_14 :	jmpneq LABEL_DROP m.psa_ingress_output_metadata_drop 0x0
	emit h.ethernet
	tx m.psa_ingress_output_metadata_egress_port
	LABEL_DROP :	drop
}


