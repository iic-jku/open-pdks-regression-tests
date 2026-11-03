v {xschem version=3.4.8RC file_version=1.3}
G {}
K {}
V {}
S {}
F {}
E {}
N 380 -250 480 -250 {lab=B}
N 380 -220 380 -200 {lab=D}
N 320 -250 340 -250 {lab=G}
N 380 -300 380 -280 {lab=S}
N 480 -250 480 -220 {lab=B}
C {devices/title.sym} 160 -30 0 0 {name=l5 author="Julian Schwarz 2026"}
C {sky130_fd_pr/pfet_g5v0d16v0.sym} 360 -250 0 0 {name=M1
W=5
L=1.05
nf=1
mult=1
ad="expr('int((@nf + 1)/2) * @W / @nf * 0.29')"
pd="expr('2*int((@nf + 1)/2) * (@W / @nf + 0.29)')"
as="expr('int((@nf + 2)/2) * @W / @nf * 0.29')"
ps="expr('2*int((@nf + 2)/2) * (@W / @nf + 0.29)')"
nrd="expr('0.29 / @W ')" nrs="expr('0.29 / @W ')"
sa=0 sb=0 sd=0
model=pfet_g5v0d16v0
spiceprefix=X
}
C {iopin.sym} 380 -300 3 0 {name=p1 lab=S}
C {iopin.sym} 380 -200 1 0 {name=p2 lab=D}
C {iopin.sym} 320 -250 2 0 {name=p3 lab=G}
C {iopin.sym} 480 -220 1 0 {name=p4 lab=B}
