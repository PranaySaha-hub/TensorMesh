# Part 3: Smart Crossroads Controller

A four-way crossroads controller. It gives green to the busiest direction, never has two greens together, and never lets a direction wait forever.

## Assumptions
- 1 tick = 1 clock cycle. Reset is synchronous and active-high.
- Directions are numbered N=0, E=1, S=2, W=3 (the tie-break order). Outputs are ordered `{W,E,S,N}`, so N is bit 0.
- Densities are sampled once, in the SELECT tick. Changes during GREEN or YELLOW are ignored until the next SELECT.
- SELECT = 1 tick (all red), GREEN = 4 + 2 x density ticks (4 to 10), YELLOW = 2 ticks. One "phase" = SELECT + GREEN + YELLOW.
- After reset the controller is in SELECT, all wait counters are 0, and W counts as "served last", so the first tie goes to N.

## Explanation
Two greens can never occur because there is only one `chosen_dir` register and the green output is built from it,
so only one bit can be high, and the SELECT tick between phases has every output red. 
No direction can starve because each one has a wait counter that goes up whenever another direction is served, and a counter that reaches 3 overrides the densities.
The worst case is when N is served three times in a row: then E, S and W all sit at 3, and they are served one after another, so the last of them (W) waits 3 + 2 = 5 phases. 
So bound on waiting is 5 phases, and the testbench checker fails the run if any direction ever waits longer.

## Results
<img width="1238" height="303" alt="image" src="https://github.com/user-attachments/assets/c7d598fa-586b-4f3f-adc5-aa31841305a3" />
