v {xschem version=3.4.8RC file_version=1.3}
G {}
K {}
V {}
S {}
F {}
E {}
N 420 -220 420 -200 {lab=C}
N 380 -250 360 -250 {lab=B}
N 420 -280 420 -300 {lab=E}
C {devices/title.sym} 160 -30 0 0 {name=l5 author="Julian Schwarz 2026"}
C {gf180mcu_fd_pr/pnp_10p00x00p42.sym} 400 -250 0 0 {name=Q1
model=pnp_10p00x00p42
spiceprefix=X
m=1
lvs_format="@name @pinlist @model"
}
C {iopin.sym} 420 -200 1 0 {name=p1 lab=C}
C {iopin.sym} 360 -250 2 0 {name=p2 lab=B}
C {iopin.sym} 420 -300 3 0 {name=p3 lab=E}
