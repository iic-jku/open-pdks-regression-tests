v {xschem version=3.4.8RC file_version=1.3}
G {}
K {}
V {}
S {}
F {}
E {}
N 380 -250 480 -250 {lab=B}
N 380 -220 380 -200 {lab=S}
N 320 -250 340 -250 {lab=G}
N 380 -300 380 -280 {lab=D}
N 480 -250 480 -220 {lab=B}
C {devices/title.sym} 160 -30 0 0 {name=l5 author="Julian Schwarz 2026"}
C {gf180mcu_fd_pr/nfet_06v0.sym} 360 -250 0 0 {name=M1
L=0.70u
W=0.42u
nf=1
m=1
ad="'int((nf+1)/2) * W/nf * 0.18u'"
pd="'2*int((nf+1)/2) * (W/nf + 0.18u)'"
as="'int((nf+2)/2) * W/nf * 0.18u'"
ps="'2*int((nf+2)/2) * (W/nf + 0.18u)'"
nrd="'0.18u / W'" nrs="'0.18u / W'"
sa=0 sb=0 sd=0
model=nfet_06v0
spiceprefix=X
}
C {iopin.sym} 380 -300 3 0 {name=p1 lab=D}
C {iopin.sym} 380 -200 1 0 {name=p2 lab=S}
C {iopin.sym} 320 -250 2 0 {name=p3 lab=G}
C {iopin.sym} 480 -220 1 0 {name=p4 lab=B}
