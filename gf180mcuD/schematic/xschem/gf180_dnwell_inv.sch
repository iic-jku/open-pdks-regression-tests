v {xschem version=3.4.8RC file_version=1.3}
G {}
K {}
V {}
S {}
F {}
E {}
N 380 -250 420 -250 {lab=S}
N 420 -250 420 -210 {lab=S}
N 380 -210 420 -210 {lab=S}
N 380 -220 380 -210 {lab=S}
N 380 -210 380 -200 {lab=S}
N 460 -150 480 -150 {lab=VSS}
N 380 -320 380 -280 {lab=out}
N 380 -400 380 -380 {lab=D}
N 380 -350 460 -350 {lab=VDD}
N 340 -350 300 -350 {lab=G}
N 340 -250 300 -250 {lab=G}
N 300 -350 300 -300 {lab=G}
N 300 -300 300 -250 {lab=G}
N 280 -300 300 -300 {lab=G}
C {devices/title.sym} 160 -30 0 0 {name=l5 author="Julian Schwarz 2026"}
C {gf180mcu_fd_pr/nfet_03v3.sym} 360 -250 0 0 {name=M1
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
model=nfet_03v3
spiceprefix=X
}
C {iopin.sym} 380 -200 1 0 {name=p2 lab=S}
C {iopin.sym} 480 -150 0 0 {name=p5 lab=VSS}
C {gf180mcu_fd_pr/pfet_03v3.sym} 360 -350 0 0 {name=M2
L=0.28u
W=0.42u
nf=1
m=1
ad="'int((nf+1)/2) * W/nf * 0.18u'"
pd="'2*int((nf+1)/2) * (W/nf + 0.18u)'"
as="'int((nf+2)/2) * W/nf * 0.18u'"
ps="'2*int((nf+2)/2) * (W/nf + 0.18u)'"
nrd="'0.18u / W'" nrs="'0.18u / W'"
sa=0 sb=0 sd=0
model=pfet_03v3
spiceprefix=X
}
C {iopin.sym} 380 -400 3 0 {name=p1 lab=D}
C {iopin.sym} 280 -300 2 0 {name=p3 lab=G}
C {iopin.sym} 460 -350 0 0 {name=p4 lab=VDD}
