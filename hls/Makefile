# C simulation of the HLS blocks with g++ and AMD's open-source ap_fixed headers.
#   make check WD=12 WR=16 SCEN=LEOKa   -> build and compare with MATLAB vectors
#   make check-all                      -> every exported configuration
WD   ?= 12
# FFT architecture: 0 = in place (II = 2), 1 = ping-pong stage buffers (II = 1)
ARCH ?= 0
WR   ?= 16
SCEN ?= LEOKa

AP   := third_party/ap_types/include
GEN  := generated
BIN  := build/tb_W$(WD)_R$(WR)_$(SCEN)_A$(ARCH)

CXXFLAGS := -std=c++14 -O2 -Wall -Wno-unknown-pragmas -Wno-unused-label -Wno-uninitialized -Wno-maybe-uninitialized \
            -I src -isystem $(AP) -I $(GEN)/R$(WR)_$(SCEN) -DWD=$(WD) -DWR=$(WR) -DFFT_ARCH=$(ARCH)

$(BIN): src/blocks.cpp src/fft.h src/types.h tb/tb_blocks.cpp $(GEN)/R$(WR)_$(SCEN)/rom_tables.h
	@mkdir -p build
	g++ $(CXXFLAGS) src/blocks.cpp tb/tb_blocks.cpp -o $@

check: $(BIN)
	./$(BIN) $(GEN)/W$(WD)_R$(WR)_$(SCEN)

# MP detector:  make mp-check MP_S=16 FRAMES=generated/mp/LEOKa_AFDM_S16_18dB.txt
# Word lengths: MPW="-DMP_WT=10 -DMP_WP=10" (see src/mp.h) with a name MPTAG=wt10wp10.
MP_S   ?= 16
MPW    ?=
MPTAG  ?= default
FRAMES ?= generated/mp/LEOKa_AFDM_S16_18dB.txt
MPBIN  := build/tb_mp_S$(MP_S)_$(MPTAG)

$(MPBIN): src/mp.cpp src/mp.h src/exp_lut.h src/types.h tb/tb_mp.cpp
	@mkdir -p build
	g++ $(CXXFLAGS) -DMP_S=$(MP_S) $(MPW) src/mp.cpp tb/tb_mp.cpp -o $@

mp-check: $(MPBIN)
	./$(MPBIN) $(FRAMES)

check-all:
	$(MAKE) check WD=10 WR=16 SCEN=LEOKa
	$(MAKE) check WD=12 WR=16 SCEN=LEOKa
	$(MAKE) check WD=16 WR=16 SCEN=LEOKa
	$(MAKE) check WD=12 WR=16 SCEN=LEOS
	$(MAKE) check WD=12 WR=16 SCEN=V2X
	$(MAKE) check WD=12 WR=16 SCEN=LEOKa ARCH=1
	$(MAKE) check WD=10 WR=16 SCEN=LEOKa ARCH=1

clean:
	rm -rf build

.PHONY: check check-all mp-check clean
