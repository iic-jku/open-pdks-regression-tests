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
N 320 -250 340 -250 {lab=G}
N 380 -300 380 -280 {lab=D}
C {devices/title.sym} 160 -30 0 0 {name=l5 author="Julian Schwarz 2026"}
C {sky130_fd_pr/nfet_03v3_nvt.sym} 360 -250 0 0 {name=M1
W=0.42
L=0.5
nf=1
mult=1
ad="expr('int((@nf + 1)/2) * @W / @nf * 0.29')"
pd="expr('2*int((@nf + 1)/2) * (@W / @nf + 0.29)')"
as="expr('int((@nf + 2)/2) * @W / @nf * 0.29')"
ps="expr('2*int((@nf + 2)/2) * (@W / @nf + 0.29)')"
nrd="expr('0.29 / @W ')" nrs="expr('0.29 / @W ')"
sa=0 sb=0 sd=0
model=nfet_03v3_nvt
spiceprefix=X
}
C {iopin.sym} 380 -300 3 0 {name=p1 lab=D}
C {iopin.sym} 380 -200 1 0 {name=p2 lab=S}
C {iopin.sym} 320 -250 2 0 {name=p3 lab=G}
