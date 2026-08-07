v {xschem version=3.4.8RC file_version=1.3}
G {}
K {}
V {}
S {}
F {}
E {}
T {Cap. MOMi 1} 1110 -1690 0 0 1 1 {}
N 1260 -980 1260 -940 {lab=v1}
N 1260 -880 1260 -840 {lab=v2}
C {title-3.sym} 0 0 0 0 {name=l1 author="Simon Dorrer" rev=1.0 lock=true}
C {devices/iopin.sym} 1260 -980 3 0 {name=p11 lab=v1}
C {devices/iopin.sym} 1260 -840 1 0 {name=p1 lab=v2}
C {sg13cmos5l_pr/cap_cmomi.sym} 1260 -910 0 1 {name=C1
model=cap_cmomi
w=5e-6
l=5e-6
mmin=1
mmax=4
feed=double
subblock=0
m=1
mm_ok=1
spiceprefix=X
}
