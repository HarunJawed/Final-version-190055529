##############################################################################
# Title			: Makefile for students VHDL laboratory work
# Project      	: EExDSA Practical Work
# Author       	: Dr. John Williams
# Copyright    	: 2018--2022 Aston University
##############################################################################
# Purpose:
# Automates using ghdl for vhdl simulation, gtkwave to view waveforms and vivado
# to syntesise and generate bit files for an FPGA
##############################################################################
# Usage :
# The conventions assumed by this makefile are given below in help definition
# below - just type `make help` to see them. 
#
# Add a separate line here for each top level unit that is to be synthesised
# defining all the sources that are to be included.
# The rules assume the top level entity name matches it's vhdl filename
# and that the xdc constraints filename
#
# Define the sources to be used here for bitfile or testbench targets
# it is important for simulations that the sources are in reverse heirarchical
# order i.e. later files have entities that depend on earlier ones.
##############################################################################


sphere_implementation.run: sphere_implementation.vhd registerfile.vhd rom.vhd
vga.check: util.check
vga_controller.check: vga.check
sphere_declarations.check: util.check vga.check rom.check dual_port_ram.check
sphere_procedural.check:  sphere_declarations.check
sphere_emulation.check:  sphere_declarations.check
sphere_assembler.check:   sphere_declarations.check
sphere_interpreter.check:  sphere_declarations.check
alu.check: sphere_declarations.check
sphere_implementation.check: sphere_declarations.check registerfile.check alu.check
sphere_mp.check: sphere_declarations.check registerfile.check alu.check
sphere_testbench.check: sphere_mp.check clk_prescaler.check
sphere.check: sphere_mp.check vga.check vga_controller.check
sphere.bit sphere.flash: sphere.vhd sphere_mp.vhd clk_prescaler.vhd sphere_declarations.vhd registerfile.vhd  vga_controller.vhd vga.vhd util.vhd dual_port_ram.vhd rom.vhd alu.vhd
julia_declarations.check:  vga.check rom.check dual_port_ram.check
julia_procedural.check:  util.check vga.check
julia_interpreter.check:  julia_declarations.check
julia_assembler.check:   julia_declarations.check
julia_interpreter.check:  julia_declarations.check
julia_mp.check:  julia_declarations.check fixed_alu.check registerfile.check
fixed_alu.check: julia_declarations.check
julia_testbench.check: julia_mp.check clk_prescaler.check
julia.check: julia_mp.check vga.check vga_controller.check
julia.bit julia.flash: julia.vhd julia_mp.vhd clk_prescaler.vhd julia_declarations.vhd util.vhd registerfile.vhd vga_controller.vhd vga.vhd util.vhd  dual_port_ram.vhd rom.vhd fixed_alu.vhd


#################################################################
# Do not change anything below this line
#################################################################

export TMPDIR=work
export LOGDIR=log

# Path to Xilinx Vivado binary
VIVADO = `(find /opt/Xilinx/ -name vivado -type f -executable || find /usr/local/Xilinx/ -name vivado -type f -executable) | grep 'bin/vivado'`

# FPGA partnumber for Basys 3 board
PARTNUMBER=xc7a35tcpg236-1
# GHDL flags work with GHDL 1.0/0.37 with mcode code generator and GNAT
# remove --warn-no-hide for version 0.36-dev
GHDLFLAGS=--std=08  --workdir=./$(TMPDIR) --warn-no-hide
GHDLRUNFLAGS= --assert-level=warning --ieee-asserts=disable-at-0
TESTBENCHES=$(wildcard *_testbench.vhd)

define help
This makefile assumes the convention that testbenches are of the form
<[uut]_testbench.vhd> where [uut] is the name of the unit under test and
that vhdl entity names match the filenames in which they are defined.
The constraints file mapping IO of top level [uut].vhd must be named
[uut].xdc

The available commands are:
make <[uut]_testbench>       - run simulation
make <[uut]_testbench.view>  - view simulation waveform
make <[uut].check>           - syntax check and analyze [uut] and dependences
make <[uut].run>             - run [uut] simulation only (no waveform)
make <[uut].debug>           - run [uut] simulation and generate waveform
make <[uut].debug.view >     - run [uut] simulation and view generated waveform
make <[top].bit>             - generate bitstream for toplevel [top].vhdl
make <[top].program>         - programe board using [top].bit
make <[top].flash>           - generate bin file and program onboard flash
make clean                   - delete all temporary generated files

Example:
make and_gate_testbench.view
will go through all the steps to analyse, elabroate and simulate the
and_gate_testbench.vhd and then run the viewer on the output waveform.
endef
export help


help:
	@echo "$$help"

sim-all: $(patsubst %.vhd,%.run,$(TESTBENCHES))

testbenches: $(patsubst %.vhd,%.run,$(TESTBENCHES))

$(TMPDIR)/%.o: %.vhd
	@mkdir -p $(TMPDIR)
	ghdl -a $(GHDLFLAGS) $<

%.check:%.vhd
	@mkdir -p $(TMPDIR)
	ghdl -a $(GHDLFLAGS) $<

%_testbench:
	@mkdir -p $(TMPDIR)
	@for f in $?; do ghdl -a $(GHDLFLAGS) "$$f" ; done
	@ghdl -m $(GHDLFLAGS) $@
	ghdl -r -v $(GHDLFLAGS) $@ --wave=$@.ghw

vga_display_file:
	@mkdir -p $(TMPDIR)
	@for f in $?; do ghdl -a $(GHDLFLAGS) "$$f" ; done
	@ghdl -m $(GHDLFLAGS) $@
	@ghdl -r -v $(GHDLFLAGS) $@

%.run:%.vhd %.check
	@mkdir -p $(TMPDIR)
#	@for f in $?; do ghdl -a $(GHDLFLAGS) "$$f" ; done
	ghdl -r  $(GHDLFLAGS) $* $(GHDLRUNFLAGS)

%.debug:%.vhd %.check
	@mkdir -p $(TMPDIR)
#@for f in $?; do ghdl -a $(GHDLFLAGS) "$$f" ; done
#	@ghdl -m $(GHDLFLAGS) $*
	ghdl -r -v $(GHDLFLAGS) $* --wave=$@.ghw $(GHDLRUNFLAGS)

%_testbench.ghw: %_testbench
	@./$*_testbench --wave=$@

%.view: %
	@gtkwave $*.ghw --output=/dev/null&

.PHONY: clean
clean:
	@ghdl --clean $(GHDLFLAGS)
	@rm -fr $(TMPDIR) $(LOGDIR) tmp *~ *.o *_testbench *webtalk.* .Xil *.ghw submission.tar *.sav

# Xilinx vivado synthesis rules

define SYNTHESIS_TCL
#step 1 read in source and constraint files
$(patsubst %.vhd,read_vhdl %.vhd;,$^)
#step 2 synthesise design
synth_design -top $* -part $(PARTNUMBER)
#step 3 run placement and logic optimisation
read_xdc $*.xdc
opt_design
power_opt_design
place_design
phys_opt_design
#step 4 run router, report actual utilisation and timing and drcs
route_design
report_utilization -file $(LOGDIR)/$*_utilisation.rpt
report_drc -file $(LOGDIR)/$*_drc.rpt
report_power -file $(LOGDIR)/$*_power.rpt
report_datasheet -file $(LOGDIR)/$*_datasheet.rpt
report_timing -file $(LOGDIR)/$*_timing.rpt
report_timing_summary -file $(LOGDIR)/$*_timing_summary.rpt
#step 5 output bitstream
set_property BITSTREAM.GENERAL.COMPRESS TRUE [current_design]
write_bitstream -force $*.bit
endef
export SYNTHESIS_TCL

define BIN_TCL
$(patsubst %.vhd,read_vhdl %.vhd;,$^)
set_property BITSTREAM.GENERAL.COMPRESS TRUE [current_design]
set_property BITSTREAM.CONFIG.CONFIGRATE 33 [current_design]
set_property BITSTREAM.STARTUP.STARTUPCLK CCLK [current_design]
set_property STEPS.WRITE_BITSTREAM.ARGS.BIN_FILE true
set_property config_mode SPIx4 [current_design]
synth_design -top $* -part $(PARTNUMBER)
read_xdc $*.xdc
place_design
route_design
write_bitstream -bin_file -force $*.bit
endef
export BIN_TCL

%.bit: 
	@mkdir -p $(TMPDIR) $(LOGDIR)
	@echo "$$SYNTHESIS_TCL" | $(VIVADO) -log $(LOGDIR)/$*_synth.log -nojournal -tempDir $(TMPDIR) -mode tcl
	@rm -fr *.jou *webtalk.* .Xil

%.bin: 
	@mkdir -p $(TMPDIR) $(LOGDIR)
	@echo "$$BIN_TCL" | $(VIVADO) -log $(LOGDIR)/$*_synth.log -nojournal -tempDir $(TMPDIR) -mode tcl
	@rm -fr *.jou *webtalk.* .Xil

define PROGRAM_TCL
set_property BITSTREAM.CONFIG.CONFIGRATE 33 [current_design]
set_property BITSTREAM.STARTUP.STARTUPCLK CCLK [current_design]
open_hw
connect_hw_server
open_hw_target
current_hw_device [lindex [get_hw_devices] 0]
refresh_hw_device -update_hw_probes false [lindex [get_hw_devices] 0]
set_property PROGRAM.FILE {$*.bit} [lindex [get_hw_devices] 0]
program_hw_devices [lindex [get_hw_devices] 0]
close_hw_target
disconnect_hw_server
close_hw
quit
endef
export PROGRAM_TCL

.PHONY: %.program
%.program: %.bit
	@mkdir -p $(TMPDIR) $(LOGDIR)
	@echo "$$PROGRAM_TCL" | $(VIVADO) -log $(LOGDIR)/$*_prog.log -nojournal -tempDir $(TMPDIR) -mode tcl
	@rm -fr *.jou *webtalk.* .Xil

#tcl instructions to program flash  - derived from using GUI
define FLASH_TCL
$(patsubst %.vhd,read_vhdl %.vhd;,$^)
set_property BITSTREAM.GENERAL.COMPRESS TRUE [current_design]
set_property BITSTREAM.CONFIG.CONFIGRATE 33 [current_design]
et_property BITSTREAM.STARTUP.STARTUPCLK CCLK [current_design]
set_property STEPS.WRITE_BITSTREAM.ARGS.BIN_FILE true
set_property config_mode SPIx4 [current_design]
synth_design -top $* -part $(PARTNUMBER)
read_xdc $*.xdc
opt_design
place_design
route_design
write_bitstream -bin_file -force $*.bit
open_hw
connect_hw_server
open_hw_target
current_hw_device [lindex [get_hw_devices] 0]
refresh_hw_device -update_hw_probes false [lindex [get_hw_devices] 0]
create_hw_cfgmem -hw_device [lindex [get_hw_devices xc7a35t_0] 0] [lindex [get_cfgmem_parts {s25fl032p-spi-x1_x2_x4}] 0]
set_property PROGRAM.BLANK_CHECK  0 [ get_property PROGRAM.HW_CFGMEM [lindex [get_hw_devices xc7a35t_0] 0]]
set_property PROGRAM.ERASE  1 [ get_property PROGRAM.HW_CFGMEM [lindex [get_hw_devices xc7a35t_0] 0]]
set_property PROGRAM.CFG_PROGRAM  1 [ get_property PROGRAM.HW_CFGMEM [lindex [get_hw_devices xc7a35t_0] 0]]
set_property PROGRAM.VERIFY  1 [ get_property PROGRAM.HW_CFGMEM [lindex [get_hw_devices xc7a35t_0] 0]]
set_property PROGRAM.CHECKSUM  0 [ get_property PROGRAM.HW_CFGMEM [lindex [get_hw_devices xc7a35t_0] 0]]
set_property PROGRAM.ADDRESS_RANGE  {use_file} [ get_property PROGRAM.HW_CFGMEM [lindex [get_hw_devices xc7a35t_0] 0]]
set_property PROGRAM.FILES [list {$*.bin}] [ get_property PROGRAM.HW_CFGMEM [lindex [get_hw_devices xc7a35t_0] 0]]
set_property PROGRAM.PRM_FILE {} [ get_property PROGRAM.HW_CFGMEM [lindex [get_hw_devices xc7a35t_0] 0]]
set_property PROGRAM.ADDRESS_RANGE  {use_file} [ get_property PROGRAM.HW_CFGMEM [lindex [get_hw_devices xc7a35t_0] 0]]
set_property PROGRAM.UNUSED_PIN_TERMINATION {pull-none} [ get_property PROGRAM.HW_CFGMEM [lindex [get_hw_devices xc7a35t_0] 0]]
create_hw_bitstream -hw_device [lindex [get_hw_devices xc7a35t_0] 0] [get_property PROGRAM.HW_CFGMEM_BITFILE [ lindex [get_hw_devices xc7a35t_0] 0]]; program_hw_devices [lindex [get_hw_devices xc7a35t_0] 0]; refresh_hw_device [lindex [get_hw_devices xc7a35t_0] 0];
program_hw_cfgmem -hw_cfgmem [ get_property PROGRAM.HW_CFGMEM [lindex [get_hw_devices xc7a35t_0] 0]]
close_hw_target
disconnect_hw_server
close_hw
quit
endef
export FLASH_TCL

.PHONY: %.flash
%.flash:
	@mkdir -p $(TMPDIR) $(LOGDIR)
	@echo "$$FLASH_TCL" | $(VIVADO) -log $(LOGDIR)/$*_prog.log -nojournal -tempDir $(TMPDIR) -mode tcl
	@rm -fr *.jou *webtalk.* .Xil

template.tar.gz: Makefile *.vhd *.xdc *.py 
	tar -czvf template.tar.gz $?

.PHONY: submission.tar
submission.tar:
	@echo `date` $$USER `hostname` > submission.txt
	@tar -cf $@ *
	@rm submission.txt
	@echo "File $@ created. Upload this file to Blackboard assignment."
