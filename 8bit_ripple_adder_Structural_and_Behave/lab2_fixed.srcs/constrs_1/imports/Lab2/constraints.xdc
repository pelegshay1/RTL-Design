## Switches
set_property -dict { PACKAGE_PIN J15   IOSTANDARD LVCMOS33 } [get_ports { a[0] }];  #SW0
set_property -dict { PACKAGE_PIN L16   IOSTANDARD LVCMOS33 } [get_ports { a[1] }];  #SW1
set_property -dict { PACKAGE_PIN M13   IOSTANDARD LVCMOS33 } [get_ports { a[2] }];  #SW2
set_property -dict { PACKAGE_PIN R15   IOSTANDARD LVCMOS33 } [get_ports { a[3] }];  #SW3
set_property -dict { PACKAGE_PIN R17   IOSTANDARD LVCMOS33 } [get_ports { a[4] }];  #SW4
set_property -dict { PACKAGE_PIN T18   IOSTANDARD LVCMOS33 } [get_ports { a[5] }];  #SW5
set_property -dict { PACKAGE_PIN U18   IOSTANDARD LVCMOS33 } [get_ports { a[6] }];  #SW6
set_property -dict { PACKAGE_PIN R13   IOSTANDARD LVCMOS33 } [get_ports { a[7] }];  #SW7

set_property -dict { PACKAGE_PIN T8    IOSTANDARD LVCMOS18 } [get_ports { b[0] }];  #SW8
set_property -dict { PACKAGE_PIN U8    IOSTANDARD LVCMOS18 } [get_ports { b[1] }];  #SW9
set_property -dict { PACKAGE_PIN R16   IOSTANDARD LVCMOS33 } [get_ports { b[2] }];  #SW10
set_property -dict { PACKAGE_PIN T13   IOSTANDARD LVCMOS33 } [get_ports { b[3] }];  #SW11
set_property -dict { PACKAGE_PIN H6    IOSTANDARD LVCMOS33 } [get_ports { b[4] }];  #SW12
set_property -dict { PACKAGE_PIN U12   IOSTANDARD LVCMOS33 } [get_ports { b[5] }];  #SW13
set_property -dict { PACKAGE_PIN U11   IOSTANDARD LVCMOS33 } [get_ports { b[6] }];  #SW14
set_property -dict { PACKAGE_PIN V10   IOSTANDARD LVCMOS33 } [get_ports { b[7] }];  #SW15



## LEDs
set_property -dict { PACKAGE_PIN H17   IOSTANDARD LVCMOS33 } [get_ports { sum[0] }]; #LED0
set_property -dict { PACKAGE_PIN K15   IOSTANDARD LVCMOS33 } [get_ports { sum[1] }]; #LED1
set_property -dict { PACKAGE_PIN J13   IOSTANDARD LVCMOS33 } [get_ports { sum[2] }]; #LED2
set_property -dict { PACKAGE_PIN N14   IOSTANDARD LVCMOS33 } [get_ports { sum[3] }]; #LED3
set_property -dict { PACKAGE_PIN R18   IOSTANDARD LVCMOS33 } [get_ports { sum[4] }]; #LED4
set_property -dict { PACKAGE_PIN V17   IOSTANDARD LVCMOS33 } [get_ports { sum[5] }]; #LED5
set_property -dict { PACKAGE_PIN U17   IOSTANDARD LVCMOS33 } [get_ports { sum[6] }]; #LED6
set_property -dict { PACKAGE_PIN U16   IOSTANDARD LVCMOS33 } [get_ports { sum[7] }]; #LED7
set_property -dict { PACKAGE_PIN V16   IOSTANDARD LVCMOS33 } [get_ports { cout }];   #LED8