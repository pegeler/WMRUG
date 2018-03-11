Why use Rcpp?
-------------

The power of Rcpp comes from the fact the C++ code has a fundamentally different *modus operandi* than R. That is, C++ is compiled whereas R is interpreted. Understanding this difference is the key to understanding why an R user might want to rewrite their code in an compiled language---namely that it will most likely run much faster. Leveraging C++ code at workflow bottlenecks is a great way to speed things up!

Scripts versus Compiled Code
----------------------------

This talk is too high-level of a view to get into the gritty details, but here are the broad-brush definitions:

Scripting (Interpreted) Language  
A language where the user feeds instructions to an interpreter at run-time. The interpreter translates the code into specific instructions for the processor in real-time. The user can interface with the interpreter interactively. These programs tend to be slower than compiled code.

Compiled Language  
A programming language in which code must be transformed from human-readable *source code* to machine-readable *object code* in advance of running the program for the first time. These languages tend to be faster-running. However, interactive coding sessions are not usually possible.

Examples:

| **Scripting** | **Compiled** |
|:-------------:|:------------:|
|       R       |     C/C++    |
|     Python    |     Java     |
|      Perl     |    FORTRAN   |
| Matlab/Octave |     Julia    |
|   JavaScript  |    Haskell   |

***Note**: These definitions are somewhat fluid. Examples are based on common usage of each language.*

Essentially, **R** is a **scripting language** and **`C`**/**`C++`** are **compiled languages**. This means that we can run any R code in an interpreter without any special preparation. However, any C++ code we make must be compiled first into machine-readable instructions specific to our chip architecture. To do this, we need a special tool called a *compiler*. Windows users don't tend to have one handy---this is why you download Windows binaries from CRAN by default.

If you have a compiler, creating object code is easy (but can get complicated!). Here is an example of how we turn a C++ source code file into a machine-readable binary program:

``` bash
g++ heaps.cpp -o heaps
```

Now we can call that program:

``` bash
# Get all possible permutations of the set {1,2,3} using Heap's algorithm
./heaps 1 2 3
##  1 2 3
##  2 1 3
##  3 1 2
##  1 3 2
##  2 3 1
##  3 2 1
```

Basic C++ syntax
----------------

R-specific C++ object classes
-----------------------------

C-R API
-------

TL;DR: Don't use it. The Rcpp API is a much easier way to write `C`/`C++` code for R. The exception might be if you are maintaining old code that is already in this ecosystem.

The Rcpp API

Links
-----

-   [`Rcpp`](https://github.com/RcppCore/Rcpp)
-   [Seamless R and C++ Integration with Rcpp](http://www.springer.com/us/book/9781461468677)
-   [`Armadillo`](https://github.com/conradsnicta/armadillo)
-   [`RcppArmadillo`](https://github.com/RcppCore/RcppArmadillo)
-   [`mvrt`](https://pegeler.github.io/mvrt)
