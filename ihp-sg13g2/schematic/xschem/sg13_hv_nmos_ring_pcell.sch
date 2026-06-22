v {xschem version=3.4.8RC file_version=1.3}
G {}
K {}
V {}
S {}
F {}
E {}
N 380 -250 480 -250 {lab=#net1}
N 380 -220 380 -200 {lab=S}
N 320 -250 340 -250 {lab=G}
N 380 -300 380 -280 {lab=D}
N 480 -180 480 -160 {lab=B}
N 480 -250 480 -240 {lab=#net1}
C {devices/title.sym} 160 -30 0 0 {name=l5 author="Julian Schwarz 2026"}
C {iopin.sym} 380 -300 3 0 {name=p1 lab=D}
C {iopin.sym} 380 -200 1 0 {name=p2 lab=S}
C {iopin.sym} 320 -250 2 0 {name=p3 lab=G}
C {iopin.sym} 480 -160 1 0 {name=p4 lab=B}
C {sg13g2_pr/sg13_hv_nmos.sym} 360 -250 0 0 {name=M1
l=0.45u
w=0.3u
ng=1
m=1
model=sg13_hv_nmos
spiceprefix=X
}
C {sg13g2_pr/ptap1_ring.sym} 480 -210 2 1 {name=R1
model=ptap1
spiceprefix=X
w=3.67e-6
l=3.34e-6
rw=0.3e-6
lvs_ignore=short
}
