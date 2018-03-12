Why use Rcpp?
-------------

The power of Rcpp comes from the fact the C++ code has a fundamentally different *modus operandi* than R. That is, C++ is compiled whereas R is interpreted. Understanding this difference is the key to understanding why an R user might want to rewrite parts of their code in an compiled language---namely that it will most likely run much faster. Leveraging C++ code at workflow bottlenecks is a great way to speed things up!

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

### Compiling Code (outside of R)

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

### Quick Sys-reqs Note

Essentially, **R** is a **scripting language** and **`C`**/**`C++`** are **compiled languages**. This means that we can run any R code in an interpreter without any special preparation. However, any C++ code we make must be compiled first into machine-readable instructions specific to our chip architecture. To do this, we need a special tool called a *compiler*. Standard Windows and Mac installs don't tend to have one handy---this is why you download Windows binaries from CRAN by default.

If you are a Windows user, you will probably need [Rtools](https://cran.r-project.org/bin/windows/Rtools/) to play along. Mac users need Xcode (I think). [`devtools`]() will let us know if we have everything we need:

``` r
# Check to make sure we have everything we need
devtools::has_devel()
```

    ## '/usr/lib/R/bin/R' --no-site-file --no-environ --no-save --no-restore  \
    ##   --quiet CMD SHLIB foo.c

    ## 

    ## [1] TRUE

If this returns `FALSE`, go download Rtools or Xcode for Win or Mac, respectively.

Basic C++ syntax
----------------

R-specific C++ object classes
-----------------------------

C-R API
-------

TL;DR: Don't use it. The Rcpp API is a much easier way to write `C`/`C++` code for R. The exception might be if you are maintaining old code that is already in this ecosystem.

The Rcpp API
------------

Demonstrations
--------------

### Demo 1: Fibonacci Numbers

Fibonacci's Sequence:

$$
F\_n = 
\\begin{cases}
  1 ,                & \\text{if } n\\leq 2\\\\
  F\_{n-1} + F\_{n-2}, & \\text{otherwise}
\\end{cases}
$$

So the first 10 numbers of the sequence will be 1, 1, 2, 3, 5, 8, 13, 21, 34, 55.

This is fun because it is recursive. Therefore a programmer may take a recursive, memoized, or iterative approach to solving. We can use this to compare R and C++ under different conditions.

First, let's define a function to verify that our outputs are correct:

``` r
verify_results <- function(FUN) {
  FUN_vec <- Vectorize(FUN, "n")
  
  identical(
    as.integer(FUN_vec(1:10)),
    c(1L, 1L, 2L, 3L, 5L, 8L, 13L, 21L, 34L, 55L)
  )
}
```

#### Recursive

Now, let's do a simple recursive function. First in R:

``` r
fibR_rec <- function(n) {
  if (n <= 2)
    return(1)
  
  sys.function()(n - 1) + sys.function()(n - 2)
}
```

Then in C++:

``` r
Rcpp::cppFunction("
int fibCpp_rec(const int n) {
  if (n <= 2)
    return 1;

  return fibCpp_rec(n - 1) + fibCpp_rec(n - 2);

}"
)
```

Now we confirm they are correct:

``` r
verify_results(fibR_rec) && verify_results(fibCpp_rec)
```

    ## [1] TRUE

Both are right. But how do they compare performance-wise?

``` r
microbenchmark::microbenchmark(
  fibR_rec(10),
  fibCpp_rec(10),
  fibR_rec(20),
  fibCpp_rec(20)
)
```

    ## Unit: microseconds
    ##            expr       min         lq        mean     median         uq
    ##    fibR_rec(10)   187.005   193.2795   204.99133   197.2335   203.0310
    ##  fibCpp_rec(10)     4.031     5.2215    14.92856     6.8950    26.8955
    ##    fibR_rec(20) 24810.504 25568.4795 27458.86880 28100.7020 28728.8885
    ##  fibCpp_rec(20)    94.238    95.1125   105.74934    96.0820   115.0295
    ##        max neval cld
    ##    392.067   100  a 
    ##     44.848   100  a 
    ##  31999.927   100   b
    ##    282.481   100  a

OK, so the C++ wins here. This is because there is a lot of overhead to all those recursive function calls in R. Less so in C++. You will find that `for` loops and recursive function calls are usually the bottlenecks in your R code. If you cannot vectorize them somehow, you might want to think about making a C++ function to speed things up.

#### Iterative

The iterative approach is probably a little smarter. Let's try again in R:

``` r
fibR_it <- function(n) {
  
  a <- 0L
  b <- 1L
  
  for (i in seq_len(n)) {
    c <- a + b
    a <- b
    b <- c
  }
  
  a
}
```

In C++...

``` r
Rcpp::cppFunction("
int fibCpp_it(const int n) 
{
if (n <= 2) return 1;

int a = 0, b = 1, c = 0;

for (int i=1; i<n; i++)
{
  c = a + b;
  a = b;
  b = c;
}

return c;

}
")
```

And does the iterative approach provide correct answers?

``` r
verify_results(fibR_it) && verify_results(fibCpp_it)
```

    ## [1] TRUE

Now how do they compare as far as speed?

``` r
microbenchmark::microbenchmark(
  fibR_it(10),
  fibCpp_it(10),
  times = 1000
)
```

    ## Unit: microseconds
    ##           expr   min     lq     mean median     uq     max neval cld
    ##    fibR_it(10) 2.657 2.9930 3.559516  3.334 4.1580  27.549  1000  a 
    ##  fibCpp_it(10) 3.163 4.3485 6.083335  5.639 7.4115 103.140  1000   b

Hmm. Suddenly the C++ code is lagging. This is probably because assignment is highly optimized in R and there is some overhead to calling the C++ function. Let's do it over a few more loops to see if that changes things:

``` r
microbenchmark::microbenchmark(
  fibR_it(30),
  fibCpp_it(30)
)
```

    ## Unit: microseconds
    ##           expr   min     lq    mean median    uq    max neval cld
    ##    fibR_it(30) 5.991 6.2655 6.73986 6.4815 6.792 16.782   100   b
    ##  fibCpp_it(30) 3.128 3.3960 4.03012 3.5565 3.837 35.911   100  a

Now we see the C++ code is catching up!

### Demo 2: Linear Algebra

Follow the link: [`mvrt`](https://pegeler.github.io/mvrt)

Links
-----

-   [`Rcpp`](https://github.com/RcppCore/Rcpp)
-   [Seamless R and C++ Integration with Rcpp](http://www.springer.com/us/book/9781461468677)
-   [`Armadillo`](https://github.com/conradsnicta/armadillo)
-   [`RcppArmadillo`](https://github.com/RcppCore/RcppArmadillo)
