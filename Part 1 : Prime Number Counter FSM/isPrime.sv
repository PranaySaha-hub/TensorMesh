// logic
// Returns 1 if x is prime. Assumes p is prime, then clears it
// if any i from 2 up to x-1 divides x exactly (x % i == 0).
function logic is_prime(input logic [3:0] x);
    logic p;
    p = (x >= 2);
    for (int i = 2; i < 16; i++)
        if (i < x && (x % i) == 0) p = 1'b0;   // found a divisor
    return p;
endfunction
