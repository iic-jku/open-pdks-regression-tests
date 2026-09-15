# Upstream reports for kpex

Copyable drafts for https://github.com/iic-jku/klayout-pex/issues, for every PDK in this
repository rather than only ihp-sg13g2 - the other benches have no report/ of their own
and point here.

Items 1 to 3: kpex 0.3.15, Magic 8.3.681, PDK deck ihp-sg13g2 1.0.1, in IIC-OSIC-TOOLS.
Items 4 and 5: kpex 0.4.1, IIC-OSIC-TOOLS 2026.08, on ihp-sg13cmos5l and gf180mcuD.

**Items 2 and 3 have been filed** as
[#198](https://github.com/iic-jku/klayout-pex/issues/198) by simi1505 on 2026-09-04, using
[upstream_issue_kpex_combined.md](upstream_issue_kpex_combined.md). Do not file them again;
the drafts stay here as the record of what was reported. **Item 1 has been posted too**, as a
comment by simi1505 on 2026-09-04 under
[#197](https://github.com/iic-jku/klayout-pex/issues/197), which was the natural home for it:
that issue already reports the Magic-versus-2.5D capacitance deviations on ihp-sg13g2 and flags
sidewall patterns as among the worst, so what we had was its root cause rather than a new report.

So of the five items here, **only 5 is still unreported**, and 4 is covered by a document kept
outside this repository. Verified against the tracker on 2026-09-14.

**kpex 2.5D is not at fault for the sidewall disagreement.** It emits the full tech-file
coefficient, which is what the coefficient means. Magic halves it. See item 1.

That holds for ihp-sg13g2 and sky130A, whose tech files match their decks. It does not hold
for ihp-sg13cmos5l, where the coefficient itself is wrong - item 4.

---

## 1. Comment for issue #197 (root cause of the sidewall deviations)

Rewritten 2026-09-04 after reading the actual tables in #197. The deck formula reproduces both of
that issue's columns to six significant figures, which is much stronger than the generic version
this replaced.

> We think most of this table has a single cause, and it is on the Magic side rather than kpex's.
>
> **Magic halves the sidewall coefficient.** The ihp-sg13g2 deck writes `defaultsidewall allm1 metal1 28.735 -0.057`, and Magic emits `0.5 * 28.735 * L / (s + offset)` with the offset additionally rounded to whole lambda, so `-0.057` is applied as `-0.05`. Your two clean sidewall patterns fall straight out of that:
>
> | pattern | your MAGIC | `14.3675 * L / (s - 0.05)` | your 2.5D | `28.735 * L / (s - 0.057)` |
> |---|---|---|---|---|
> | `sidewall_100um_length_200nm_distance_m1` | 9.57833 fF | 9.57833 fF | 20.0944 fF | 20.09441 fF |
> | `sidewall_20um_length_200nm_distance_m1` | 1.91567 fF | 1.91567 fF | 4.01888 fF | 4.01888 fF |
>
> Six significant figures on all four. The ratio is `2 * (s - 0.05) / (s - 0.057)`, which is 2.0979 at a 200 nm gap and tends to 2 as the gap grows, and that is exactly why those two rows read 109.8 % while your wider-spaced ones read 100.1 %.
>
> Applying that to the same-layer pairs across your tables:
>
> | pattern, net pair | 2.5D / MAGIC |
> |---|---|
> | `near_body_shield_m1_m2` TOPA;TOPB | 2.0012 |
> | `sideoverlap_fingered_m1_m2` F1;F2 | 2.0051 |
> | `sideoverlap_fingered_m1_m2` F2;F3 | 2.0079 |
> | `sideoverlap_plates_m1_m2` FullHalo;NoHaloInsideTop | 2.0014 |
> | `sideoverlap_plates_m1_m2` FullHalo;OutsideHalo | 2.0014 |
> | `sideoverlap_plates_m1_m2` FullHalo;PartialSideHaloSeparated | 2.0028 |
> | `sideoverlap_plates_m1_m2` NoHaloInsideTop;OutsideHalo | 2.0014 |
> | `sideoverlap_plates_m1_m2` NoHaloInsideTop;Touching | 2.0006 |
> | `sidewall_100um_length_200nm_distance_m1` A;B | 2.0979 |
> | `sidewall_20um_length_200nm_distance_m1` A;B | 2.0979 |
> | `sidewall_cap_vpp_04p4x04p6_m1_redux` C0;C1 | 2.1144 |
> | `sidewall_net_uturn_m1_redux` C0;C1 | 2.0057 |
> | `sidewall_non_parallel_m1` B;C | 2.0105 |
>
> Thirteen of the fifteen deviating same-layer pairs, all within a couple of percent of the predicted ratio. **Two are not**, and would need a separate explanation:
>
> - `sideoverlap_fingered_m1_m2` LOWER_...Fingered1;Fingered4 at 3.8944
> - `sidewall_non_parallel_m1` A;B at 3.7890
>
> Both happen to be close to 2 x 1.9, so removing the halving would still leave roughly a factor 1.9 on non-adjacent fingers and on the non-parallel pair. Those look like a genuinely different effect, perhaps in how the edge search handles non-facing or diagonal edges.
>
> **kpex 2.5D is the correct one here.** The halving is a recent Magic regression: [51522d6](https://github.com/RTimothyEdwards/magic/commit/51522d6889bf0f80695d6e2948a7a12d172eb1c7) (2026-08-02, 8.3.678 to 8.3.679) added it in `ExtCouple.c` on the stated grounds that "both edges will be checked, causing a double-count, so each edge should contribute half of the total". On two parallel wires the second edge is not checked, so the halving is never undone. [c81b995](https://github.com/RTimothyEdwards/magic/commit/c81b995266921e4786f17e4a93667b2d36678d52) only moved it into the tech-file parser, so it is not a fix, and master still halves. Before 8.3.679 there was no halving anywhere, so this table would have looked very different a month ago.
>
> That the coefficients are meant as the full value is stated in the same commit message: "This measure was taken because the open PDK values generated by 'capiche' were not halving the value, so I either change magic or I change all the tech files."
>
> An independent check, since "which of the two models is right" should not rest on reading a commit message. A mesh-converged FasterCap solve (`--delaunay_amax 0.1 --tolerance 0.01`, raw-matrix asymmetry 0.03 % to 0.16 %) of two Metal1 wires at five spacings gives 6.2195, 3.6468, 2.0777, 1.0585 and 0.4364 fF for 0.2, 0.4, 0.8, 1.6 and 3.2 um. Magic sits below that at every spacing by 23 % to 56 %, while the full coefficient straddles it, which is what a fitted `1/(s+off)` form does against a curve of a different shape. So the field solve backs 2.5D, though it also suggests the IHP coefficients could stand a re-fit in their own right.
>
> We have filed the Magic side as [magic#557](https://github.com/RTimothyEdwards/magic/issues/557).
>
> One note on the overlap rows, which are a modelling difference rather than a bug on either side: Magic applies a halo split that sends part of a covered plate's edge fringe to the substrate, and 2.5D does not. On a 10 x 10 um TopMetal1 plate centred on a 30 x 30 um Metal1 plate, Magic gives 1.6024 fF plate-to-plate plus 0.7957 fF to substrate, 2.5D gives 2.3178 fF plate-to-plate, and FasterCap gives 2.2861 plate-to-plate with 0.1267 to substrate and 0.3809 leaving the simulation box. 2.5D is the closer one there too. On adjacent layers the two agree within 1.4 %, and on TopMetal2 over TopMetal1 Magic is closer, so it is a deep-stack effect rather than a general problem with the halo model.
>
> All of this reproduces from a bench of 63 metal-only layouts with hand-computable expected values: [`ihp-sg13g2/pex_bench`](https://github.com/iic-jku/open-pdks-regression-tests/tree/add-pex-bench/ihp-sg13g2/pex_bench) in `iic-jku/open-pdks-regression-tests`, `make pex-bench-defects`.

---

## 2. New issue: --mesh is silently ignored

**Title**

    --mesh has no effect: FasterCap runs in auto mode, which overrides -m

**Body**

    kpex 0.3.15.

    kpex invokes FasterCap as

        FasterCap -b -i -v -a0.05 -d0.5 -m0.5 -f2 -ap <input.lst>

    and FasterCap's own output then says

        Auto calculation with max error: 0.05
        Remark: Auto option overrides all other Manual settings

    so the -m that --mesh sets is passed and then discarded. Measured: --mesh 0.5 and 0.05 at a
    fixed --delaunay_amax 2 --tolerance 0.01 both give 5.95038 fF, bit-identical.

    --d_coeff does still work despite the remark (0.5 gives 2.11695 fF, 0.1 gives 2.05183 fF), so
    FasterCap's wording is broader than its behaviour and only -m is genuinely discarded.

    The failure mode is quiet and misleading rather than loud. Sweeping --mesh over 0.5, 0.25,
    0.12 and 0.06 on the same structure returns four bit-identical numbers, which reads as a
    converged result and is nothing of the kind. We spent a while concluding "the solver does not
    respond to mesh refinement" before reading the FasterCap log.

    The knob that does move the answer is --delaunay_amax, the KLayout-side triangulation. On two
    Metal1 wires 0.2 um apart at a fixed --tolerance 0.01 the coupling goes 5.89728, 5.89221,
    5.95038, 6.05837, 6.21951 fF for amax 50, 10, 2, 0.5, 0.1, so the default of 50 um^2 reads
    5.2 % below the finest point. --tolerance moves it too, as the -a it maps to is the one setting
    auto mode honours.

    Suggestions, any of which would help:

    - drop -a when the user sets --mesh, so the manual setting takes effect
    - or warn when --mesh is set, and name --delaunay_amax and --tolerance as the knobs that work
    - document --delaunay_amax as the mesh control, and consider a smaller default for
      technologies with sub-micron spacings
    - the raw capacitance matrix asymmetry is a good convergence tell and is already written to
      *_FasterCap_Result_Matrix_Raw.csv; surfacing it in the log would let users see convergence
      without post-processing

    Reproduction: ihp-sg13g2/pex_bench in iic-jku/open-pdks-regression-tests, scripts/kpex_conv.sh.

---

## 3. New issue: RC mode emits a duplicated resistor network

Low priority if RC support is still being built out, but the netlist is wrong rather than coarse,
so worth recording.

**Title**

    --magic_mode RC emits duplicated resistors that short the ports together

**Body**

    kpex 0.3.15 with Magic 8.3.681.

    A single Metal1 net shaped as an asymmetric tee: three arms of 99.5, 299.5 and 200 um meeting
    at one junction, a port at the end of each arm, nothing else in the layout.

        kpex --pdk ihp-sg13g2 --cell tee_asym_m1 --gds tee_asym_m1.gds \
             --magic --magic_mode RC --out_dir out --out_spice out/out.spice

    gives

        R0 b c      21.9565
        R1 a b      10.9565
        R2 b c      21.9565     <- duplicate of R0
        R3 a b      10.9565     <- duplicate of R1
        R4 b a.n0   32.9345  \
        R5 a.n0 c   21.9565   |  the correct star, via the internal node
        R6 a.n0 a   10.9565  /

    R4, R5 and R6 are the correct network and match the arm lengths (299.5 um at 110 mOhm/sq =
    32.945 Ohm, and so on). R0 to R3 are two duplicated pairs on top of it, connecting ports that
    the star already connects through a.n0. They short it:

        port pair    correct    kpex RC
        a to b       43.8910    4.5661     9.6x low
        a to c       32.9130   10.9710     3.0x low
        b to c       54.8910    8.2328     6.7x low

    Driving Magic directly with the same recipe reproduces it, so it is in the recipe rather than
    in the netlist post-processing. For comparison, Magic driven with `extract do resistance` and
    `extresist threshold 0 / minres 0 / mindelay 0` emits exactly the three-resistor star.

    Two things about that recipe that may be related:

    - it issues `extresist tolerance 1`, which current Magic answers with "Note: This option has
      been deprecated and is unused". So --magic_tolerance has no effect.
    - it sets no `extresist threshold`, `minres` or `mindelay`, so RC extraction runs at Magic's
      defaults with no way to change them from kpex. That matters because Magic's default
      `mindelay 1` drops resistor arms and can leave ports unconnected, which we have written up
      separately for the Magic tracker. Exposing those three would make RC runs controllable and
      would replace the deprecated option.

    Reproduction: ihp-sg13g2/pex_bench in iic-jku/open-pdks-regression-tests,
    scripts/try_kpexrecipe.sh.

---

## 4. Already written up elsewhere, do not duplicate

The ihp-sg13cmos5l tech file carrying ihp-sg13g2's coefficients is covered by
`klayout-pex-docu/Issue_cmos5l_sidewall_coefficients.md` (in Julian's `eda/designs`, outside
this repository), written 2026-09-07 in a parallel effort and ready to file. That audit is the
one to send: it checks all 107 coefficients against the deck rather than only the sidewall
block, and it names the root cause in the generator.

    36 of 107 wrong, all of them ihp-sg13g2 values:
      sidewall             6   20.8 % to 78.8 %
      sideoverlap         26   0.11 % to 3.34 %
      substrate perimeter  4   0.25 % to 3.09 %
    area quantities correct throughout
    cause: cxx/gen_tech_pb/pdk/ihp_sg13.cpp builds both PDKs from one function; where an
    is_g2() branch exists because the layer set differs the cmos5l value was entered, where
    the layer exists in both but the value differs the sg13g2 value stands

This bench found the six sidewall entries independently, from table H, and at first concluded
that the other blocks were fine. **That conclusion was wrong**, and the reason is worth keeping:
it came from diffing `ihp-sg13cmos5l_tech.pb.json` against `ihp-sg13g2_tech.pb.json`, where a
coefficient that is wrong *because* it equals ihp-sg13g2's reads as identical. Only a comparison
against the PDK's own deck finds those.

Tracker searched 2026-09-14, nothing open for `cmos5l`. Closed
[#179](https://github.com/iic-jku/klayout-pex/issues/179), a wrong Metal2 thickness in
`ihp-sg13g2_tech.pb.json`, is the precedent for this class and was fixed.

Two notes for whoever files it: that document depends on `Issue_cmos5l_missing_rule_decks.md`
being filed first, because without the rule decks the coefficient error is not observable at
all. And `klayout-pex-docu` is not a git repository, so those documents exist in one copy only.

---

## 5. New issue: gf180mcuD's top metal crashes 2.5D and is silently wrong to substrate

Found 2026-09-08 with kpex 0.4.1 while porting this bench to gf180mcuD. Tracker searched
2026-09-14: no hit for `MetalTop`. Worth cross-linking
[#156](https://github.com/iic-jku/klayout-pex/issues/156), our own gf180mcuD test-pattern
results - its patterns stop at Metal4, which is why the crash never showed up there.

**Title**

    gf180mcuD: metal5_con maps to original_layer_name "MetalTop", which no parasitics table knows

**Body**

    kpex 0.4.1, IIC-OSIC-TOOLS 2026.08.

    In klayout_pex_protobuf/gf180mcuD_tech.pb.json the computed layer for the top metal is

        {"kind": "KIND_REGULAR",
         "layer_info": {"purpose": "PURPOSE_METAL", "name": "metal5_con",
                        "description": "Computed layer for met5",
                        "drw_gds_pair": {"layer": 81}},
         "original_layer_name": "MetalTop"}

    while the layer itself is declared as Metal5 and every parasitics table names it
    Metal5. "MetalTop" appears in exactly one other place in the file, a stray row in
    `substrates`, and nowhere in `overlaps`, `sideoverlaps`, `sidewalls` or the
    `process_stack`. One wrong string, two separate failures.

    1. Hard crash on any cell whose fringe extraction touches the top metal:

        RuntimeError: KeyError: 'MetalTop' in EdgeNeighborhoodVisitor.on_edge
          klayout_pex/rcx25/c/sidewall_and_fringe_extractor.py:383
          klayout_pex/rcx25/c/sidewall_and_fringe_extractor.py:246 in Region.complex_op

       raised from sidewall_and_fringe_extractor.py:100. In this bench that is a 10 x 10 um
       Metal5 plate over a 30 x 30 um Metal4 plate, and the same over Metal1.

    2. Silent wrong value where it does not crash. The stray substrates row is

        {"layer_name": "MetalTop", "area_capacitance": 6.32, "perimeter_capacitance": 38.85}

       Those are **sky130A's** met5 coefficients, not gf180mcuD's, which are 5.798 and
       30.386. A 50 x 50 um Metal5 plate plus a 0.5 x 50 um Metal5 wire therefore comes out
       at 23.5703 fF where the deck gives 20.5722 fF, 14.6 % high. Cross-check on the wire
       alone: kpex returns 4.0822 fF and sky130A's own deck predicts 4.0819 fF for that
       structure, so the provenance of the number is not in doubt.

    Magic extracts the same layouts correctly, and the FasterCap engine is unaffected because
    it field-solves the process stack instead of looking the layer up in the parasitics
    tables - `kpex --fastercap` on the cell that crashes 2.5D completes normally.

    Suggested fix: set original_layer_name to "Metal5" for metal5_con, and drop the MetalTop
    row from substrates. A tech-file self-check that every original_layer_name resolves to a
    layer the parasitics tables know would have caught both, and would be worth having for
    the other PDKs too.

    Reproduction: gf180mcuD/pex_bench in iic-jku/open-pdks-regression-tests, make pex-bench.
    The two crashing cells are listed in KPEX_KNOWN_FAILS there so the rest of the run
    completes.
