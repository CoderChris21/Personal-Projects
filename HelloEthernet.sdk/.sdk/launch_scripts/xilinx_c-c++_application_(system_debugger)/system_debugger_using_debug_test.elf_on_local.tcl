connect -url tcp:127.0.0.1:3121
configparams mdm-detect-bscan-mask 2
targets -set -nocase -filter {name =~ "microblaze*#0" && bscan=="USER2"  && jtag_cable_name =~ "Digilent Arty A7-100T 210319BCC2D8A"} -index 0
rst -processor
targets -set -nocase -filter {name =~ "microblaze*#0" && bscan=="USER2"  && jtag_cable_name =~ "Digilent Arty A7-100T 210319BCC2D8A"} -index 0
dow C:/Users/ChristopherSam/XilinxProjects/HelloEthernet/HelloEthernet.sdk/Test/Debug/Test.elf
bpadd -addr &main
