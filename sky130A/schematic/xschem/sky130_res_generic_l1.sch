v {xschem version=3.4.8RC file_version=1.3}
G {}
K {}
V {}
S {}
F {}
E {}
N 400 -280 400 -300 {lab=R0}
N 400 -220 400 -200 {lab=R1}
C {devices/title.sym} 160 -30 0 0 {name=l5 author="Julian Schwarz 2026"}
C {sky130_fd_pr/res_generic_l1.sym} 400 -250 0 0 {name=R1
W=0.4
L=2
model=res_generic_l1
mult=1
}
C {iopin.sym} 400 -300 3 0 {name=p1 lab=R0}
C {iopin.sym} 400 -200 1 0 {name=p2 lab=R1}
