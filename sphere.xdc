## Constraints file with connections for synthesising sphere example microprocessor
## Project      : EExDSA Practical Work
## Author       : Dr. John Williams
## Copyright    : 2020--2022 Aston University

# some common required settings for Basys 3 boards
set_property CONFIG_VOLTAGE 3.3 [current_design]
set_property CFGBVS VCCO [current_design]
set_property IOSTANDARD LVCMOS33 [get_ports -regexp { .* }]

## Clock signal - not needed for unclocked logic
set_property PACKAGE_PIN W5 [get_ports sys_clk]							
create_clock -add -name sys_clk_pin -period 10.0 -waveform {0 5} [get_ports sys_clk]	

## LEDs
set_property PACKAGE_PIN U16 [get_ports {hlt}]								

###Buttons
set_property PACKAGE_PIN U18 [get_ports reset]								

##VGA Connector
set_property PACKAGE_PIN G19 [get_ports {vgaRed[0]}]				
set_property PACKAGE_PIN H19 [get_ports {vgaRed[1]}]				
set_property PACKAGE_PIN J19 [get_ports {vgaRed[2]}]				
set_property PACKAGE_PIN N19 [get_ports {vgaRed[3]}]				
set_property PACKAGE_PIN N18 [get_ports {vgaBlue[0]}]				
set_property PACKAGE_PIN L18 [get_ports {vgaBlue[1]}]				
set_property PACKAGE_PIN K18 [get_ports {vgaBlue[2]}]				
set_property PACKAGE_PIN J18 [get_ports {vgaBlue[3]}]				
set_property PACKAGE_PIN J17 [get_ports {vgaGreen[0]}]				
set_property PACKAGE_PIN H17 [get_ports {vgaGreen[1]}]				
set_property PACKAGE_PIN G17 [get_ports {vgaGreen[2]}]				
set_property PACKAGE_PIN D17 [get_ports {vgaGreen[3]}]				
set_property PACKAGE_PIN P19 [get_ports Hsync]						
set_property PACKAGE_PIN R19 [get_ports Vsync]						


### Local Variables:
### mode: tcl
### End:
