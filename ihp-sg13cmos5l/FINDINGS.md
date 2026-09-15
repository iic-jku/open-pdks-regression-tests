# Findings and work-arounds for the ihp-sg13cmos5l PDK

Things in this PDK that are easy to get wrong and frustrating to troubleshoot. The ihp-sg13g2 counterpart is [../ihp-sg13g2/FINDINGS.md](../ihp-sg13g2/FINDINGS.md).

## No DigiSub layer

This PDK has no `DigiSub` layer, so the ihp-sg13g2 work-around for devices with a built-in guard ring (a `DigiSub` rectangle over the active area, see the ihp-sg13g2 findings) does not exist here. The cells in this directory only pass LVS with tap extraction disabled, which is what `sak-lvs.sh` does for both flows.

## No NBuLay layer

`NBuLay` does not exist in this PDK. A layout copied from ihp-sg13g2 can still carry shapes on it: this PDK's layer list does not show the layer, so the shapes are invisible, but DRC and LVS still flag them. Delete them after copying.

## cap_cmomi pins

The pins must lie outside of the bus connection. The LVS extractor derives its ports as `metal<n>_pin.and(recog_mom)`, so every metal pin polygon inside the `Recog.mom` marker counts as a device port, and it needs exactly two. The marker spans the whole device including the bus connections, so a pin dropped on a bus is counted on top of the two the PCell already draws. At four ports the device is not extracted, and if it was the only device in the cell the layout netlist comes out empty.

**Symptom:** `cap_cmomi: expected exactly 2 port regions under the Recog.mom marker, found 4` in the KLayout log, then an empty `.SUBCKT`.

**Work-around:** Run a short metal stub out past the `Recog.mom` boundary and put the pin and its label on the stub. Moving only the label does nothing, it is the pin polygon that gets counted.

The extractor lives in the ihp-sg13g2 deck (`custom_mom_extractor.lvs`), so this applies to both PDKs.
