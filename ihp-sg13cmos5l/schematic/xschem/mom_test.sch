v {xschem version=3.4.8RC file_version=1.3}
G {}
K {}
V {}
S {}
F {}
E {}
T {MOM Test} 1110 -1690 0 0 1 1 {}
N 1260 -980 1260 -960 {lab=v1}
N 1260 -980 1360 -980 {lab=v1}
N 1260 -1000 1260 -980 {lab=v1}
N 1360 -980 1360 -960 {lab=v1}
N 1260 -860 1260 -840 {lab=v2}
N 1360 -860 1360 -840 {lab=v2}
C {title-3.sym} 0 0 0 0 {name=l1 author="Simon Dorrer" rev=1.0 lock=true}
C {devices/iopin.sym} 1260 -1000 3 0 {name=p11 lab=v1}
C {devices/iopin.sym} 1260 -840 1 0 {name=p1 lab=v2}
C {cap_cmomi_1.sym} 1260 -910 0 1 {name=x1}
C {cap_cmomi_1.sym} 1360 -910 0 0 {name=x2}
C {devices/iopin.sym} 1360 -840 1 0 {name=p2 lab=v3}
