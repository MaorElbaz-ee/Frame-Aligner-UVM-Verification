# Frame Aligner - UVM Verification Environment

## Background - what was given
- **The DUT:** `frame_aligner`, an RTL block that finds frame boundaries in a byte stream.
- **The spec:** a document with a state diagram and waveforms.
- **Inputs:** `clk`, `reset`, and `rx_data` (one byte per clock).
- **Outputs:**
  - `frame_detect`: 1 while the block is aligned.
  - `fr_byte_position`: the position of the current byte inside the frame.
- **Frame format:** 12 bytes. A 2-byte header (LSB first) is followed by 10 payload bytes. There are two legal headers:
  - `AA AF` (HEAD_1)
  - `55 BA` (HEAD_2)
- **Lock:** the block becomes aligned after 3 consecutive legal frames.
- **Loss of lock:** the block drops alignment after 48 bytes without a legal frame.

## Goal
Build a UVM verification environment that checks the DUT against the spec, then find and document any bugs.

## Process
1. **Define expected behavior.** Wrote down what the block should do, based on the spec.
2. **Verification plan.** Listed the features and corner cases to verify. Examples:
   - a header inside the payload
   - the 48th non-aligned byte
   - repeated LSBs
   - mixed headers
3. **Environment.** Built the driver, monitor, scoreboard with a reference model, coverage, and SVA in the interface. Ran basic tests (lock, unlock) to confirm the environment and the basic assumptions.
4. **Directed tests.** Wrote a sequence and a test for each corner case in the plan. Each bug has a control test that shows the same scenario passing when the bug condition is absent.
5. **Random and regression tests.**
   - A constrained-random test with variable payload lengths.
   - A regression test that runs all scenarios, used to collect total coverage.

## What we found
Three bugs in `Frame_aligner.sv`, all visible at the DUT outputs. Full details and logs are in [`FINDINGS_final.md`](FINDINGS_final.md).

| # | Bug | Caught by |
|---|-----|-----------|
| 1 | While aligned, after a bad header, the DUT searches for a header on every byte. A header pattern inside the payload shifts the frame grid, and `frame_detect` stays 1. | `frame_false_lock_test` |
| 2 | A valid LSB in place of the MSB is dropped instead of being re-checked as a new LSB. The DUT never locks on `AA AA AF`, `AA 55 BA`, or `55 AA AF`. | `frame_lsb_lsb_msb_test`, `frame_cross_retest_test` |
| 3 | An LSB followed by an invalid byte makes `fr_byte_position` show 1 for one cycle while searching. It should stay 0. | `frame_cross_hdr_test` |

**Other insights:**
- **The spec contradicts itself.** Waveform 2 conflicts with the state diagram about the position after an LSB followed by an invalid byte. We followed the waveform.
- **Bugs 2 and 3 were hidden at first.** The reference model was first built from the state diagram, so it agreed with the DUT and reported nothing. Comparing the DUT against the spec waveforms exposed the gap. After updating the model, it catches both bugs.
- **Bug 1 also shows up in the random test.** The DUT keeps locking on fake headers in the payload, so it never unlocks. The reference model locked and unlocked 5 times.

## Environment architecture
```
test -> sequence
           |
+----------|------------------ env -------------------------+
|  +-------v------------- agent ---------------+            |
|  |  sequencer --> driver         monitor     |            |
|  +-------------------|--------------^---|----+            |
|                      |              |   +--> scoreboard   |
|                      |              |   |    (ref model)  |
|                      |              |   +--> coverage     |
+----------------------|--------------|---------------------+
                       v              |
          interface (clocking blocks, SVA)
                       |              ^
                       v              |
                 DUT: frame_aligner --+
```

## Files
| File | Role |
|------|------|
| `Frame_aligner.sv` | DUT |
| `interface.sv` | interface, clocking blocks, SVA |
| `tb_top.sv` | top module: clock, reset, DUT instance, `run_test` |
| `frame_types_pkg.sv` | monitor report struct |
| `frame_pkg.sv` | package - includes all UVM classes (item, driver, monitor, scoreboard, coverage, agent, env, sequences, tests) |
| `FINDINGS_final.md` | bugs found |

## Compile order
```
frame_types_pkg.sv
frame_pkg.sv
interface.sv
Frame_aligner.sv
tb_top.sv
```
All other `.sv` files are included by `frame_pkg.sv` (they must be in the include path).

## Running a test
`tb_top` runs `frame_lock_test` by default. To run another test:
```
+UVM_TESTNAME=<test name>
```
Extra plusargs:
- `frame_cross_retest_test`: `+swap=1` runs `55 AA AF` (default `AA 55 BA`)
- `frame_random_test`: `+num_frames=N` (default 50)

Every test prints a scoreboard summary (`SCB_SUMMARY`) and a coverage summary (`COV_SUMMARY`) at the end.

## Tests
| Test | What it checks | Expected result |
|------|----------------|-----------------|
| `frame_lock_test` | lock after 3 valid frames and hold | pass |
| `frame_unlock_test` | lock, loss of lock after 48 bytes, relock | pass |
| `frame_spec_test` | lock on HEAD_1, unlock, relock on HEAD_2 | pass |
| `frame_mixed_hdr_test` | lock on alternating HEAD_1 / HEAD_2 | pass |
| `frame_payload_hdr_ok_test` | control for bug 1: header in payload with valid header / while not aligned | pass |
| `frame_false_lock_test` | bad header + header planted in payload while aligned | **fail - bug 1** |
| `frame_lsb_lsb_msb_test` | `AA AA AF` while aligned / not aligned / acquiring | **fail - bug 2** |
| `frame_lsb_lsb_lsb_msb_test` | control for bug 2: `AA AA AA AF` - DUT locks | locks (1 position error from bug 3 expected) |
| `frame_cross_retest_test` | `AA 55 BA` / `55 AA AF` | **fail - bug 2** |
| `frame_cross_hdr_test` | mixed headers `AA BA` / `55 AF` | **fail - bug 3** |
| `frame_na47_hdr_test` | header completed exactly on the 48th non-aligned byte | pass for the 48-byte loss; late relock from **bug 1** (13 position + 12 frame_detect errors) |
| `frame_random_test` | lock, then constrained-random frames (payload 10-40) | informational |
| `frame_regression_test` | all scenarios in one run - for total coverage only (error count is not meaningful) | coverage |

## Documents
- [`docs/Verification Plan.xlsx`](docs/Verification%20Plan.xlsx) - the verification plan: features, corner cases, and the test that covers each one.
- [`docs/Frame Aligner - Findings.pdf`](docs/Frame%20Aligner%20-%20Findings.pdf) - the findings report (PDF version of `FINDINGS_final.md`).
