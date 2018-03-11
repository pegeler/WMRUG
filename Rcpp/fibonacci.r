# fibonacci.r
# Exploring Code Optimization through the Fibonacci Sequence
#
# Paul W. Egeler, M.S., GStat
# 22 Dec 2017
#
# Inspired by Dirk Eddelbuettel's Rcpp book
library(Rcpp)

# Define a verification function --------------------------------------------

verify_results <- function(FUN) {
  FUN_vec <- Vectorize(FUN, "n")
  
  identical(
    as.integer(FUN_vec(1:10)),
    c(1L, 1L, 2L, 3L, 5L, 8L, 13L, 21L, 34L, 55L)
  )
}

# Simple recursive function ------------------------------------------------
# R
fibR_rec <- function(n) {
  if (n <= 2)
    return(1)
  
  sys.function()(n - 1) + sys.function()(n - 2)
}

verify_results(fibR_rec)

# C++
cppFunction("
int fibCpp_rec(const int n) {
  if (n <= 2)
    return 1;

  return fibCpp_rec(n - 1) + fibCpp_rec(n - 2);

}"
)

verify_results(fibCpp_rec)

microbenchmark::microbenchmark(
  fibR_rec(10),
  fibCpp_rec(10),
  fibR_rec(20),
  fibCpp_rec(20)
)

# Iterative function ------------------------------------------------------
# R
fibR_it1 <- function(n) {
  if (n <= 2) return(1L)
  a <- 0L
  b <- 1L
  
  for (i in seq_len(n-1)) {
    c <- a + b
    a <- b
    b <- c
  }
  
  c
}
fibR_it2 <- function(n) {
  
  a <- 0L
  b <- 1L
  
  for (i in seq_len(n)) {
    c <- a + b
    a <- b
    b <- c
  }
  
  a
}


verify_results(fibR_it1)
verify_results(fibR_it2)

# C++
cppFunction("
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

verify_results(fibCpp_it)

microbenchmark::microbenchmark(
  fibR_it1(10),
  fibR_it2(10),
  fibCpp_it(10),
  times = 1000
)


  
