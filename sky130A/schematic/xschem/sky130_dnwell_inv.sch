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
C {sky130_fd_pr/nfet_01v8.sym} 360 -250 0 0 {name=M1
W=0.42
L=0.15
nf=1
mult=1
ad="expr('int((@nf + 1)/2) * @W / @nf * 0.29')"
pd="expr('2*int((@nf + 1)/2) * (@W / @nf + 0.29)')"
as="expr('int((@nf + 2)/2) * @W / @nf * 0.29')"
ps="expr('2*int((@nf + 2)/2) * (@W / @nf + 0.29)')"
nrd="expr('0.29 / @W ')" nrs="expr('0.29 / @W ')"
sa=0 sb=0 sd=0
model=nfet_01v8
spiceprefix=X
}
C {iopin.sym} 380 -200 1 0 {name=p2 lab=S}
C {iopin.sym} 480 -150 0 0 {name=p5 lab=VSS}
C {sky130_fd_pr/pfet_01v8.sym} 360 -350 0 0 {name=M2
W=0.42
L=0.15
nf=1
mult=1
ad="expr('int((@nf + 1)/2) * @W / @nf * 0.29')"
pd="expr('2*int((@nf + 1)/2) * (@W / @nf + 0.29)')"
as="expr('int((@nf + 2)/2) * @W / @nf * 0.29')"
ps="expr('2*int((@nf + 2)/2) * (@W / @nf + 0.29)')"
nrd="expr('0.29 / @W ')" nrs="expr('0.29 / @W ')"
sa=0 sb=0 sd=0
model=pfet_01v8
spiceprefix=X
}
C {iopin.sym} 380 -400 3 0 {name=p1 lab=D}
C {iopin.sym} 280 -300 2 0 {name=p3 lab=G}
C {iopin.sym} 460 -350 0 0 {name=p4 lab=VDD}
