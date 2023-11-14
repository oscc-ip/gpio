NOVAS        := /eda/tools/snps/verdi/R-2020.12/share/PLI/VCS/LINUX64
EXTRA        := -P ${NOVAS}/novas.tab ${NOVAS}/pli.a		

VERDI_TOOL   := verdi
SIM_TOOL     := vcs
SIM_OPTIONS  := -full64 -debug_acc+all  +v2k -sverilog -timescale=1ns/10ps \
				${EXTRA} \
				+error+500\
				+define+SVA_OFF\
				-work DEFAULT\
				+vcs+flush+all \
				+lint=TFIPC-L \
				+define+S50 \
				-kdb \

SRC_FILE ?=
SRC_FILE += ../../common/rtl/register.sv
SRC_FILE += ../../common/rtl/interface/apb4_if.sv
SRC_FILE += ../../common/rtl/model/apb4_master_model.sv
SRC_FILE += ../rtl/apb4_archinfo.sv 
SRC_FILE += ../tb/apb4_archinfo_tb.sv

comp:
	@mkdir -p build
	cd build && (${SIM_TOOL} ${SIM_OPTIONS} -top apb_archinfo_tb -l compile.log $(SRC_FILE))

all:simv

run: comp
	cd build && ./simv -l run.log

verdi:
	${VERDI_TOOL} -ssf asic_top.fsdb &

.PHONY : clean simv verdi

clean :
	rm -rf build
