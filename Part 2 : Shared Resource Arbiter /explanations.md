# Part 2: Shared Resource Arbiter

Two modules (A and B) send 8-bit data to one shared output. The arbiter picks who sends each cycle.

## Files
- `SharedBusRouter.sv`: Version 1, fixed priority (A wins a tie)
- `SharedBusRouter_RoundRobin.sv`: Version 2, round-robin (the other module wins a tie)
- `tb_fixed.sv`, `tb_rr.sv`: self-checking testbenches (print PASS or FAIL)

## How to run
```
iverilog -g2012 -o sim_fixed SharedBusRouter.sv tb_fixed.sv && vvp sim_fixed
iverilog -g2012 -o sim_rr SharedBusRouter_RoundRobin.sv tb_rr.sv && vvp sim_rr
```
(I ran them in Vivado XSim; Icarus Verilog works too.)

## Assumptions
- Reset(rst) is synchronous and active-high 
- Outputs are registered, so a grant appears one clock after the request.
- In Version 2, a 1-bit memory remembers who was granted last. It resets to "A was last", so the first tie goes to B.
- An idle cycle (no requests) does not change memory
- The loser keeps its request high until it is served.


Answers

Q1. Both requests at the same time**

Both requests held high from cycle 1:

| Cycle | req_A | req_B | V1 grant | V2 grant |
|---|      ---|      ---|       ---|---|
| 1 |       1 |       1 |        A | B |
| 2 |       1 |       1 |        A | A |
| 3 |       1 |       1 |        A | B |
| 4 |       1 |       1 |        A | A |

V1: A always wins. V2: the grants alternate.

Q2. Problem with always giving A priority

B is starved: if A keeps requesting, B is never served. Both requests held high for 20 cycles:

| Version           | A grants      | B grants |
|---                |---            |---|
| V1 fixed priority | 20            | 0 |
| V2 round-robin    | 10            | 10 |

Q3. How V2 is fair, and the longest B waits**

memory records who was granted last, and on a tie the other module wins. So neither module can win twice in a row while both are requesting. The longest B waits is **1 cycle** (it waits behind at most one grant of A).



## Results
Both testbenches print PASS. (Add your console screenshot or paste the output here.)
