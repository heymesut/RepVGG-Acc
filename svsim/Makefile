##
## -------------------------------------------------------------
##    Copyright 2010-2011 Synopsys, Inc.
##    All Rights Reserved Worldwide
##
##    Licensed under the Apache License, Version 2.0 (the
##    "License"); you may not use this file except in
##    compliance with the License.  You may obtain a copy of
##    the License at
##
##        http://www.apache.org/licenses/LICENSE-2.0
##
##    Unless required by applicable law or agreed to in
##    writing, software distributed under the License is
##    distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
##    CONDITIONS OF ANY KIND, either express or implied.  See
##    the License for the specific language governing
##    permissions and limitations under the License.
## -------------------------------------------------------------
##

x: all

#
# Include file for VCS Makefiles
#


#
# Note that +acc and +vpi have an adverse impact on performance
# and should not be used unless necessary.
#
# They are used here because they are required by some examples
# (backdoor register accesses).
#

TEST = /usr/bin/test
N_ERRS = 0
N_FATALS = 0

VCS =	vcs -sverilog -timescale=1ns/1ns \
	    +acc +vpi \
	    -CFLAGS -DVCS -LDFLAGS -Wl,-no-as-needed -full64 -cpp g++-4.8 -cc gcc-4.8 \
	    -fsdb

SIMV = 	./simv \
		-l vcs.log \
		+fsdb+sva_success \
		-assert report \
		-assert summary \
		-cm assert

all: comp run

comp:
	$(VCS) -f filelist.f -assert enable_diag -cm assert
# $(VCS) +incdir+../dut +incdir+../tb \
# ./top_tb.v

run:
	$(SIMV)
	$(URG)

# coverage report
URG  = urg -dir simv.vdb

CHECK = \
	@$(TEST) \( `grep -c 'UVM_ERROR :    $(N_ERRS)' vcs.log` -eq 1 \) -a \
		 \( `grep -c 'UVM_FATAL :    $(N_FATALS)' vcs.log` -eq 1 \)

# generate filelist
# LIST = find $(dir) -name "*.sv" -o -name "*.svh" -o -name "*.v" -o -name "*.vh" >./filelist.f

list:
	$(LIST)

# verdi
wave:
# $(LIST)
	verdi -sv -f ./filelist.f -ssf *.fsdb -nologo

clean:
	rm -rf *~ core csrc simv* vc_hdrs.h ucli.key urg* *.log *.fsdb

