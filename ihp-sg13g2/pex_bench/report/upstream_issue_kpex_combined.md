# Combined kpex issue

One issue covering the two kpex-side findings, as an alternative to the per-finding drafts in
[upstream_issues_kpex.md](upstream_issues_kpex.md). Copy the title, then everything below the rule.

The sidewall deviation of [klayout-pex#197](https://github.com/iic-jku/klayout-pex/issues/197) is
deliberately not repeated here: it is a Magic-side regression, filed as
[magic#557](https://github.com/RTimothyEdwards/magic/issues/557), and kpex 2.5D is the correct one.
This issue only points at it.

**Title**

    --mesh is silently ignored, and --magic_mode RC emits duplicated resistors

---

kpex 0.3.15, Magic 8.3.681, PDK ihp-sg13g2 1.0.1, in IIC-OSIC-TOOLS.

Two findings from building a PEX regression suite of 63 metal-only dummy layouts whose parasitics follow from the PDK extraction deck by hand, so every extracted value has a closed-form expected value. It lives in [`ihp-sg13g2/pex_bench`](https://github.com/iic-jku/open-pdks-regression-tests/tree/add-pex-bench/ihp-sg13g2/pex_bench) of `iic-jku/open-pdks-regression-tests`.

Neither is about the capacitance model. Where the 2.5D engine and Magic disagree on the sidewall term, which is what the deviating rows of #197 mostly are, the 2.5D engine is the one that matches both the tech-file coefficients and a converged FasterCap solve: that turned out to be a Magic regression in 8.3.679 and is filed as [magic#557](https://github.com/RTimothyEdwards/magic/issues/557). On the overlap term the two also differ, by Magic's halo split, and there the field solve does not favour 2.5D everywhere: it is closer on six of the eight layer pairs we measured, and Magic is closer on TopMetal2 over TopMetal1 (5.8 % against 12.9 %).

## 1. `--mesh` has no effect

Holding everything else fixed and varying `--mesh` by a factor of ten gives a bit-identical result:

    kpex --pdk ihp-sg13g2 --cell sidewall_m1_s0p2 --gds sidewall_m1_s0p2.gds --fastercap \
         --delaunay_amax 2 --tolerance 0.01 --mesh <value>

    --mesh 0.5   -> CCext_1_2  5.95038f
    --mesh 0.05  -> CCext_1_2  5.95038f

and a four-point sweep at default settings is identical too (0.5, 0.25, 0.12, 0.06 all give 2.11695 fF on a second cell).

The cause is visible in the FasterCap invocation kpex builds:

    FasterCap -b -i -v -a0.05 -d0.5 -m0.06 -f2 -ap <input>.lst

`-m` is passed, but so is `-a`, and FasterCap then reports

    Auto calculation with max error: 0.05
    Remark: Auto option overrides all other Manual settings

The failure mode is quiet and actively misleading rather than loud. A `--mesh` sweep returns identical numbers, which reads as a converged result and is nothing of the kind. We spent a while concluding "the solver does not respond to mesh refinement" before reading the FasterCap log, and that wrong conclusion made it into a draft report.

Two knobs do move the answer, so this is only about `--mesh`:

- `--delaunay_amax`, the KLayout-side triangulation, is the effective mesh control. On two Metal1 wires 0.2 um apart at a fixed `--tolerance 0.01`, the coupling goes 5.89728, 5.89221, 5.95038, 6.05837, 6.21951 fF for amax 50, 10, 2, 0.5, 0.1. The default of 50 um^2 therefore reads 5.2 % below the finest point, and is far coarser than the 0.2 um gap it is meshing.
- `--d_coeff` does still have an effect despite the "overrides all other Manual settings" remark: 0.5 gives 2.11695 fF and 0.1 gives 2.05183 fF on the same cell. So FasterCap's remark is broader than its actual behaviour, and only `-m` is genuinely discarded.

Suggestions, any of which would help:

- drop `-a` when the user sets `--mesh`, so the manual setting takes effect
- or warn when `--mesh` is set, and name `--delaunay_amax` and `--tolerance` as the knobs that work
- document `--delaunay_amax` as the mesh control, and consider a smaller default for technologies with sub-micron spacings
- the raw capacitance matrix asymmetry is a good convergence tell and is already written to `*_FasterCap_Result_Matrix_Raw.csv`. Surfacing it in the log, weighted by magnitude and thresholded so a sign flip on a near-zero entry does not dominate, would let users see convergence without post-processing. On this bench it runs 0.03 % to 0.16 % on converged structures and 18 % on one that is nowhere near.

## 2. `--magic_mode RC` emits duplicated resistors that short the ports

A single Metal1 net shaped as an asymmetric tee: three arms of 99.5, 299.5 and 200 um meeting at one junction, a port at the end of each arm, nothing else in the layout.

    kpex --pdk ihp-sg13g2 --cell tee_asym_m1 --gds tee_asym_m1.gds \
         --magic --magic_mode RC --out_dir out --out_spice out/out.spice

gives

    R0 b c      21.9565
    R1 a b      10.9565
    R2 b c      21.9565     <- duplicate of R0
    R3 a b      10.9565     <- duplicate of R1
    R4 b a.n0   32.9345  \
    R5 a.n0 c   21.9565   |  the correct star, through the internal node
    R6 a.n0 a   10.9565  /

R4, R5 and R6 are the correct network and match the arm lengths (299.5 um at 110 mOhm/sq = 32.945 Ohm, and so on). Magic driven directly with `extract do resistance` and `extresist threshold 0 / minres 0 / mindelay 0` emits exactly those three and nothing else:

    R0 c.n0 b   32.9345
    R1 c.n0 c   21.9565
    R2 a c.n0   10.9565

R0 to R3 in the kpex output are two duplicated pairs on top of that star, connecting ports the star already connects through `a.n0`. They short it:

    port pair    correct    kpex RC    
    a to b       43.8910     4.5661     9.6x low
    a to c       32.9130    10.9710     3.0x low
    b to c       54.8910     8.2328     6.7x low

Two things in the generated `*_MAGIC_RC_Script.tcl` that may be related:

    ext2sim labels on
    ext2sim -p <dir>
    extresist tolerance 1
    extresist all
    ext2spice extresist on

- `extresist tolerance` is answered by current Magic with `Note:  This option has been deprecated and is unused.`, so `--magic_tolerance` has no effect.
- the script sets no `extresist threshold`, `minres` or `mindelay`, so RC extraction runs at Magic's defaults with no way to change them from kpex. That matters because Magic's default `mindelay 1` drops resistor arms and can leave ports unconnected, which is finding 3 of [magic#557](https://github.com/RTimothyEdwards/magic/issues/557). Exposing those three would make RC runs controllable and would replace the deprecated option.

We understand RC support may still be under construction, so treat the priority accordingly. Recording it because the netlist is wrong rather than merely coarse: a consumer of it sees a to b as 4.57 Ohm where the geometry says 43.89.

## Reproducing

Both cases are in the bench. `make pex-bench-defects` covers the Magic-side findings, and `scripts/kpex_conv.sh` plus `scripts/try_kpexrecipe.sh` cover these two. Happy to run any experiment on it, and happy to split this into two issues if you prefer.
