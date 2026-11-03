v {xschem version=3.4.8RC file_version=1.3}
G {}
K {}
V {}
S {}
F {}
E {}
N 400 -280 400 -300 {lab=A}
N 400 -220 400 -200 {lab=C}
C {devices/title.sym} 160 -30 0 0 {name=l5 author="Julian Schwarz 2026"}
C {gf180mcu_fd_pr/diode_pw2dw.sym} 400 -250 0 0 {name=D1
model=diode_pw2dw
r_w=1u
r_l=1u
m=1
}
C {iopin.sym} 400 -300 3 0 {name=p1 lab=A}
C {iopin.sym} 400 -200 1 0 {name=p2 lab=C}
