# Upstream reports from the PEX bench

Copyable drafts for https://github.com/RTimothyEdwards/magic/issues.

All numbers are from Magic 8.3 r681, PDK deck ihp-sg13g2 1.0.1, kpex 0.3.15, in IIC-OSIC-TOOLS.
Every case reproduces with `make pex-bench-defects` in `ihp-sg13g2/pex_bench` of `iic-jku/open-pdks-regression-tests`.

Search done on 2026-09-04. Already reported, do not open again:

| Finding | Existing issue |
| --- | --- |
| full-RC counts coupling capacitance twice | [#550](https://github.com/RTimothyEdwards/magic/issues/550), open, 0 comments, no reproduction case. Add the comment below instead. |
| full-RC segfault on an ihp-sg13g2 layout | [#532](https://github.com/RTimothyEdwards/magic/issues/532), open. A crash, not one of ours. |
| extresist non-determinism | [#538](https://github.com/RTimothyEdwards/magic/issues/538), [#551](https://github.com/RTimothyEdwards/magic/issues/551), open. |

Nothing found for the four below. Note for number 5: the halving is deliberate and recent, introduced by [51522d6](https://github.com/RTimothyEdwards/magic/commit/51522d6889bf0f80695d6e2948a7a12d172eb1c7) on 2026-08-02 (8.3.678 to 8.3.679), and [c81b995](https://github.com/RTimothyEdwards/magic/commit/c81b995266921e4786f17e4a93667b2d36678d52) only moved it from the calculation to the parser without changing the result. Neither is a fix, and master still halves. Report it as a regression against the stated intent, not as a long-standing modelling choice.

---

## 1. Comment to add to issue #550

> Confirming this from the extracted netlists, with a minimal case and numbers.
>
> Magic 8.3 r681, PDK ihp-sg13g2 1.0.1, in IIC-OSIC-TOOLS.
>
> Two parallel Metal1 wires, 0.5 um wide, 200 um long, 0.2 um apart, each with a short stub so both nets branch and qualify for resistance extraction. Same GDS, two runs.
>
> C-coupled (`extract all`, no resistance), which is the reference:
>
> ```
> C0 s1 s0   19.1567f     <- coupling
> C1 s1 sub  14.0930f
> C2 s0 sub  14.0930f
> ```
>
> Full RC (`extresist threshold 10000`, `minres 1000`, `mindelay 0`, `extract do resistance`, `ext2spice extresist on`):
>
> ```
> R0..R5                  <- correct, arm values within 0.1 %
> C0 s1 s0     19.1567f   <- the coupling capacitor is still here
> C1 s1    w#  15.00077f
> C2 b1    w#   4.35815f
> C3 a1    w#   4.37121f
> C8 s1.n0 w#   9.51957f
> ```
>
> The four substrate capacitors of net `s1` sum to 33.2497 fF, which is exactly 14.0930 + 19.1567: the true substrate capacitance plus the whole of the coupling, spread over the RC nodes, while the coupling element is also emitted. Node `s0` therefore carries 52.4 fF where the correct answer is 33.25 fF.
>
> On the smallest possible case, two coupled wires with no resistor network at all, it reads `7.85871 = 3.06954 + 4.78917` on each node, to the last digit.
>
> On a real cell (a 176-transistor inverter macro) the total extracted capacitance goes from 248.4 fF to 510.8 fF, and the output node from 35.8 fF to 60.8 fF, an over-estimate of 70 %.
>
> Reproduction, one make target: `ihp-sg13g2/pex_bench` in https://github.com/iic-jku/open-pdks-regression-tests, `make pex-bench-defects`.

---

## 2. New issue: extresist mindelay

**Title**

```
extresist: a non-zero mindelay drops resistor arms and leaves ports connected to nothing
```

**Body**

```markdown
Magic 8.3 r681, PDK ihp-sg13g2 1.0.1, in IIC-OSIC-TOOLS.

One Metal1 net shaped as a cross: four arms of 199.5, 199.5, 299.5 and 199 um meeting at one junction, a port at the end of each arm, nothing else in the layout.

With `extresist threshold 0`, `minres 0`, `mindelay 0` the network is correct:

```
.subckt cross_m1 w e s n
R0 n.n0 e   32.9345      # 299.5 um at 110 mOhm/sq = 32.945
R1 n.n0 s   21.9565
R2 w n.n0   21.9565
R3 n.n0 n   21.8245
.ends
```

With `mindelay 1` (threshold 10000, minres 1000):

```
.subckt cross_m1 w e s n
R0 n s      21.9565
R1 w n      21.9565
.ends
```

Two problems. Port `e` is declared and appears in no element, so it is a floating node in simulation. Port `n` is silently aliased onto the junction, so its 21.82 Ohm arm reads zero. A three-arm tee behaves the same way, losing a 32.93 Ohm arm.

Any non-zero `mindelay` does this and the value does not matter: 1, 2 and 10 behave alike. `minres`, which is documented as the network simplification control, is innocent here: it merges nothing at 1000 mOhm on 11 Ohm arms, as expected.

Separately, an unbranched net gets no resistance at all unless `threshold` and `mindelay` are *both* 0. A 1 um wide, 1000 um long Metal1 wire is 110 Ohm with 115 fF to substrate, an RC delay of 12.6 ps, and it extracts as an ideal short at any non-zero threshold, including 1 mOhm. Adding a third port in the middle changes nothing. The log shows `Nets extracted: 1` followed by `Nets output: 0`, so the resistance is computed and then discarded. On a branched net the threshold does behave as documented, surviving at 10000 mOhm and disappearing at 100000, bracketing that net's real 10.96 Ohm.

Reproduction: `ihp-sg13g2/pex_bench` in https://github.com/iic-jku/open-pdks-regression-tests, `make pex-bench-defects` (case 2).
```

---

## 3. New issue: extract no coupling

**Title**

```
"extract no coupling" discards inter-net capacitance instead of referring it to ground
```

**Body**

```markdown
Magic 8.3 r681, PDK ihp-sg13g2 1.0.1, in IIC-OSIC-TOOLS.

Two parallel Metal1 wires, 0.5 um wide, 50 um long, 0.2 um apart.

With coupling (`extract all`):

```
C0 a b    4.78917f
C1 b sub  3.06954f
C2 a sub  3.06954f
```

With `extract no coupling`:

```
C0 b sub  4.87346f
C1 a sub  4.87346f
```

4.87346 fF is exactly what one of these wires extracts on its own, with no neighbour in the layout at all. So the neighbour is not being referred to ground, it is being ignored: the coupling is dropped, and the shielding it applies to the substrate fringe is dropped with it. Each wire should carry 3.06954 + 4.78917 = 7.859 fF if the neighbour is treated as an AC ground, and it carries 4.873 fF instead.

On a real cell this is not a small effect. On a 176-transistor inverter macro, `extract no coupling` emits four capacitors in total, all output-to-VSS; VDD and every input net come out with no parasitic capacitance at all, against 42.2 fF of real wiring capacitance on each input in the coupled run. Total extracted capacitance is 166.5 fF against 248.4 fF coupled, so a third of it is gone.

This matters because "decoupled" extraction is the fast option people reach for on large layouts, where the routing is densest and the omission is largest.

Reproduction: `ihp-sg13g2/pex_bench` in https://github.com/iic-jku/open-pdks-regression-tests, `make pex-bench-defects` (case 3).
```

---

## 4. New issue: ext2spice hierarchy

**Title**

```
ext2spice hierarchy on moves a net's substrate capacitance onto other nets
```

**Body**

```markdown
Magic 8.3 r681, PDK ihp-sg13g2 1.0.1, in IIC-OSIC-TOOLS.

One `sg13g2_inv_1` standard cell with a 0.5 x 200 um Metal2 wire added on its gate net `A`, reached through one Via1 in the pin. By the PDK extraction deck that wire is worth about 15.8 fF to substrate, and there is nothing else in the layout it could belong to. Flattened, extracted with `extract all`, written with `ext2spice cthresh 0.01`.

`ext2spice hierarchy off`:

```
C3 Y   VSS   0.16752f
C4 A   VSS  15.9216f     <- the wire, on the net it is drawn on
C5 VDD VSS   0.13605f
```

`ext2spice hierarchy on`, same layout:

```
C3 Y   VSS   8.12832f    <- 0.16752 + 7.9608
C4 VDD VSS   8.09685f    <- 0.13605 + 7.9608
                         <- A has no capacitance at all; 2 x 7.9608 = 15.9216
```

The wire's entire capacitance leaves the net it belongs to and lands in two exact halves on the output and the supply.

On a larger cell the total is not even conserved. On a 176-transistor inverter macro, hierarchy on loses 40.5 fF of 288.9 fF, all of it substrate capacitance, with four input nets and VDD left at exactly zero. Every coupling capacitor is unchanged in both cases.

Device-less layouts are unaffected: three metal-only test structures give byte-identical netlists either way, so this only appears once the layout contains devices.

Worth flagging because `ext2spice lvs` sets `hierarchy on`, so any flow that starts from that shortcut and then re-enables capacitance (`ext2spice cthresh <value>`) is affected without the user choosing hierarchical output. Setting `hierarchy on` alone reproduces it exactly, and `ext2spice lvs` followed by `ext2spice hierarchy off` restores the full total; the shortcut's other effects (`global off`, `blackbox on`, `subcircuit top auto`, `format ngspice`) each make no difference on their own.

Reproduction: `ihp-sg13g2/pex_bench` in https://github.com/iic-jku/open-pdks-regression-tests, `make pex-bench-defects` (case 4).
```

---

## 5. New issue: sidewall coefficient halved (a regression in 8.3.679)

Rewritten 2026-09-04 after finding the commit that introduced it. It is a regression with a known
commit and version, and the maintainer's own commit message supplies the specification.

**Title**

```
Sidewall capacitance is half the tech-file coefficient since 8.3.679 (the assumed double-count does not happen)
```

**Body**

```markdown
Magic 8.3 r681, PDK ihp-sg13g2 1.0.1, in IIC-OSIC-TOOLS. Current master (8.3.683) behaves the same.

51522d6 ("Multiple changes", 2026-08-02, 8.3.678 -> 8.3.679) changed the sidewall coefficient convention so that the tech file carries the actual coefficient and magic halves it, on the grounds stated in `extract/ExtCouple.c`:

> Important!  The sidewall coeffient is correct for the coupling between
> edges, but both edges will be checked, causing a double-count, so each
> edge should contribute half of the total.

On two parallel wires the second edge is not checked, so the halving is never undone and the emitted capacitance is half of the coefficient the tech file carries.

Two Metal1 wires, 0.5 um wide, 50 um long, separation swept. Deck line:

```
defaultsidewall allm1 metal1 28.735 -0.057
```

| separation [um] | coefficient x L / (s + offset) | magic emits |
| --- | --- | --- |
| 0.2 | 10.0472 | 4.7892 |
| 0.4 | 4.1888 | 2.0525 |
| 0.8 | 1.9337 | 0.9578 |
| 1.6 | 0.9311 | 0.4635 |
| 3.2 | 0.4571 | 0.2281 |

Exactly `0.5 * coefficient * L / (s + offset)` at all five, to five digits. Writing `57.470` in the tech file instead returns the expected value (1.91567 fF at 0.8 um against 1.93371 expected, the residual being the offset quantisation below), which confirms the single application of the 0.5 is the whole effect. The explicit `sidewall` keyword behaves identically to `defaultsidewall`.

Before 8.3.679 there was no halving anywhere, so a deck carrying capiche's coefficients extracted the full value. This is what makes it a regression: the same layout and the same PDK give half the sidewall coupling they gave in 8.3.678.

That the open-PDK coefficients are the full value, not the pre-halved one, is stated in the same commit message:

> Changed the way that magic interprets the "sidewall" coefficient so that it is entered into the tech file as the actual sidewall coefficient instead of being half the value to correct for magic's double counting of edges. The correction is instead done when parsing the tech file. This measure was taken because the open PDK values generated by "capiche" were not halving the value, so I either change magic or I change all the tech files.

Two independent checks that the full value is the intended one:

- KLayout's kpex reads the identical coefficients for this PDK (`sidewall 28.735, offset -0.057`) and its 2.5D engine emits the full value at every spacing. The two tools agree to six digits on `areacap`, `perimc` and `overlap` and differ by exactly two only here.
- A mesh-converged FasterCap solve of the same structures (raw-matrix asymmetry 0.03 % to 0.16 %) gives 6.2195, 3.6468, 2.0777, 1.0585 and 0.4364 fF for the five spacings. Magic is below that at every spacing by 23 % to 56 %; the full coefficient straddles it, which is what a fitted `1/(s+off)` form does against a curve of a different shape.

Separately and more minor: the offset is rounded to whole lambda, so the deck's -0.057 um is applied as -0.05 um. Worth 4.7 % at 0.2 um spacing and nothing above 1 um.

Reproduction: `ihp-sg13g2/pex_bench` in https://github.com/iic-jku/open-pdks-regression-tests, `make pex-bench-defects` (case 5).
```

---

## 6. Optional, weaker: halo fringe attribution

Worth raising only if the maintainer wants it, since on adjacent layers the split is harmless and on one pair Magic is the closer of the two models. Consider attaching to [#183](https://github.com/RTimothyEdwards/magic/issues/183) (check parasitic models against PDK data) rather than opening separately.

**Title**

```
Shielded plate's edge fringe is attributed to the substrate rather than to the plate below
```

**Body**

```markdown
Magic 8.3 r681, PDK ihp-sg13g2 1.0.1.

A 10 x 10 um TopMetal1 plate centred on a 30 x 30 um Metal1 plate, so the upper plate is completely covered and its edges are 10 um inside the lower plate's outline.

| | top to bottom | top to substrate | top to far field |
| --- | --- | --- | --- |
| Magic | 1.6024 | 0.7957 | no such node |
| kpex 2.5D, same coefficients, no halo split | 2.3178 | none | no such node |
| FasterCap | 2.2861 | 0.1267 | 0.3809 |

Magic's halo split sends 0.80 fF of the upper plate's edge charge to the substrate, against 0.51 fF the field solve puts outside the plate-to-plate path (0.13 to substrate plus 0.38 leaving upward), and takes it out of the plate-to-plate coupling, which it then under-reports by 30 %. Metal3 over Metal1 shows the same shape, 19 % below the solve against 13 % for the unsplit model.

For adjacent layers the two models agree within 1.4 % and the split does not matter, and on TopMetal2 over TopMetal1 Magic is in fact the closer of the two, so this is a deep-stack effect rather than a problem with the halo model as such.

Reproduction: `ihp-sg13g2/pex_bench` in https://github.com/iic-jku/open-pdks-regression-tests, `make pex-bench-defects` (case 6).
```
