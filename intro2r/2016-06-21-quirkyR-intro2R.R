###############################################################################
# 
#               RRRRRRR
#               RRR   RRR
#               RRR   RRR
#               RRRRRRR
#               RRR   RRR
#               RRR    RRR
#               RRR    RRR
#               RRR    RRR
#               
#       West Michigan R Users Group
#
###############################################################################
# 
#   TITLE:    quirkyR:
#             An introduction to R for programmers
#             Basics, quirks, and gotchas
#             --or--
#             YARD: Yet another R demo...
#           
#   AUTHOR: Paul Egeler
#
#   CONTACT: paulegeler .at. gmail .dot. com  
#   
#   DATE:   21 Jun 2016
#   
#   PURPOSE:
# 
#   R is awesome. R is great. R fills a niche. R is weird.  
# 
#   There are a lot of bright people out there in many different technical 
#   disciplines. These bright people, who may be giants in their own respective
#   fields, do not always have formal training in computer science or 
#   programming. And yet, over the course of their work they may find utility 
#   in using computational support to augment their work. 
#   
#   In such cases, one often enlists a familiar office productivity suite 
#   produced somewhere in Washington state. However, reliance on spreadsheets 
#   for heavy-duty computing tasks can be inelegant, cumbersome, and limiting. 
#   Think back to psychology 101--The Sapir-Whorf hypothesis. As such, better 
#   understanding of the tools available can facilitate better analysis.
# 
#   This script is meant to introduce the R language to a person of technical
#   background who heretofore has had limited exposure to the language
#   but who is familiar with computing concepts. The neophyte will
#   (hopefully) become comfortable with the R environment, try some basic
#   data wrangling, and identify some of the pitfalls commonly encountered
#   by newbies and seasoned programmers alike.
#   
#   I hope there will be something to take away in here for folks of
#   all skill levels!
#
###############################################################################
#
#   Some must-read resources:
#
#   aRrgh: a newcomer's (angry) guide to R
#   http://arrgh.tim-smith.us/
#     
#   The R Inferno
#   http://www.burns-stat.com/documents/books/the-r-inferno/
#   
#   Impatient R
#   http://www.burns-stat.com/documents/tutorials/impatient-r/
# 
#   Google's R Style Guide
#   https://google.github.io/styleguide/Rguide.xml
# 
#   magrittr
#   https://cran.r-project.org/web/packages/magrittr/vignettes/magrittr.html
# 
#   Advanced R by Hadley Wickham
#   http://adv-r.had.co.nz/
#
#   R Language Definition
#   https://cran.r-project.org/doc/manuals/r-release/R-lang.html
#
#   Many of these resources have been the source material and/or springboard
#   for my talk today, particularly aRrgh and R Inferno. If you liked my talk,
#   I encourage you to check out the websites for yourself!
#
###############################################################################

###############
# Outline
###############
# 
# I. Fundamentals
#  A. Simple calculation
#  B. Ending commands
#  C. Naming
# II. Assignment
#  A. (Not) declaring variables
#  B. <-
#  C. =
#  D. ->
#  E. assign()
#  F. <<-
# III. Environment
#  A. get(); setwd()
#  B. ls()
#  C. rm()
# VI. Data types
#  A. Atomic vectors
#  B. Matrices/Arrays
#  C. Lists
#  D. data.frames
#  E. Factors
#  F. Grab bag (TRUE, FALSE, NA, NULL)
# V. Indexing
#  A. []
#  B. $
#  C. [[]]
#  D. Various tricks
# VI. Functions
#  A. Defining functions
#  B. Lazy evaluation
# VII. Using vectorization to your advantage
#  A. For loops vs. vector operations
#  B. sapply/tapply/lapply
#  C. Recycling vectors
# VIII. Libraries
#  A. magrittr
#  B. dplyr
#  C. tidyr

###############
# Fundamentals
###############

# R can be used as a calculator

5 * 2 + 3

sqrt(1 - (3/4)^2)

9 * 0:10       # Vectorized operations

# Statements are ended with line breaks or semicolons
print("Hello world.")
print("Hello");print("world.")

# Statements can be extended over multiple lines
# NOTE: The console prompt changes from '>' to '+'
head(mtcars)   # Peek at the data frame

plot(          # Create a plot of MPG by weight
  mtcars$wt,
  mtcars$mpg,
  xlab = "Weight (lb/1000)",
  ylab = "Miles/US Gal"
)

# Statements can be grouped by curly braces
if (TRUE) {
  print("This command is within an IF structure")
  print("So is this one")
}
  
# Naming conventions:
# Full stop is a legal character in naming and is preferred over
# camelCase and underscores
# 
# For variables
# total.sales       # Good
# totalSales        # OK
# total_Sales       # Bad
# 
# For functions
# getArea()         # Good
# get_area()        # Bad
# 
# Unlike SAS, R is case sensitive!
# GET.AREA != get.area


###############
# Assignment
###############

# There are many object types in R, but they are not usually declared 
# prior to assignment
character(5)
integer(10)

# To assign a value to a variable, simply use an assignment operator
# The recommended assignment method is the <- operator
# This is the safest way to assign a value to a variable

x <- 1:10     # Note the colon operator (:) generates a sequence
print(x)      # Print the object with the print function
x             # Or simply submit the object to the console

x < - 1:10     # Careful with whitespace when using the arrow operator!

# I like the equal sign operator (=) because it's fewer keystrokes
# NOTE: This can get you in trouble in some situations

x = 10:1
x

# Parentheses automatically print
(y <- -5:5)

# The arrow operator works bidirectionally
15:1 -> z
z

# Can also assign variables using the assign() function
assign("a", 1:5)
a

# The double angle brace in assignment operator assigns the value to
# the parent environment (i.e., global environment)
# NOTE: The use of this operator is inadvisable except in very specific situations
foo = function () x.global <<- "I am being assigned to the global environment"
foo()
x.global

###############
# Environment
###############

# Speaking of the environment, here are a couple of useful 
# environment mangaement functions

getwd()                   # Get working directory of R process
setwd("~/")               # ~/ expansion works even in Windows environment
list.files()              # List files in working directory

ls()                      # Kinda UNIX-y, eh?
ls(pattern = "^x")        # regex pattern matching
ls(envir = .GlobalEnv)    # This comes in handy when searching for an object
                          # whilst still in a function

set.seed(999)             # Creates a random seed, which is a hidden object
ls(all.names = TRUE)      # Handy for finding hidden objects (denoted by full stop)
                          # such as random seed 

rm(foo)                   # Also kind UNIX-y, right?

# This is an example of a quick way to remove all objects matching a pattern
#rm(list = ls(pattern = "^x")) 

###############
# Data types
###############

# Some of the basic objects
# Called atomic vectors
class(1:5)
class(1:5 + .2)
class("foo")
class(TRUE)

# To concatenate elements into a vector, use c()
c(1,3,5)
c("foo","bar","baz")
c("foo",1,2)  # Note the coercion

# NA is the R representation of missing values
# Much like SAS's dot "."
# Be very careful if you know your data contains "NA" strings!!!
c(1,2,NA)     # NA is missing
c(1,2,"NA")   # NA is NOT missing!
c(1,2,NaN)    # NaN is not a number
c(1,2,Inf)    # Inf is infinity

## Logical vectors
# NOTE: T/F are aliases for TRUE/FALSE--They can be overwritten
x = 1:5

x <  5
x == 4
x != 3
x >= 2
1 %in% 1:3

1 < 3 & 3 < 5    # Same as "1 < 3 < 5" (which will not work)
1 == 2 | 1 != 2  # | is OR operator. %>% is pipe (with magrittr package)

## Factors 

# Factors most closely resemble the SAS PROC FORMAT construct
# Data is saved as integers but are _USUALLY_ represented as
# strings by most functions, as referenced by the "levels"
# attribute, which is a character vector

my.factor = factor(
  rep(letters[1:3], times=4),
  levels = letters[1:4]       # Levels do not have to match input vector
)

print(my.factor)
levels(my.factor)
nlevels(my.factor)
unclass(my.factor)

# If you have levels which you would like to treat as numbers,
# life gets a little sticky...
my.factor2 = factor(rep(101:103,each = 2))

as.numeric(my.factor2)  # Thanks to R Inferno for the next couple of lines

# The fix:
as.numeric(as.character(my.factor2))

# Or better still:
as.numeric(levels(my.factor2))[my.factor2]

## Lists
# Lists are vectors where each element can be a different type
# The list class is essentially a container for any R object type
# Object types can be mixed and matched


my.list = list(
  numeric.vector = 1:10,
  character.vector = c("foo","bar","baz"),
  data.frame = head(mtcars,3)
)

my.list
my.list[3]           # Single element of list object
my.list[[3]]         # Different indexing operator, slightly different result
my.list$data.frame   # Yet another indexing operator

## Data frames (d.f's)

# Data frames are lists of column vectors, all of which have the same length
# Vectors constituting the d.f can be of different data types
# This object makes a 2 dimensional table much like a SAS dataset
# Atrributes such as [column] names and row.names can be appended

d.f =  data.frame(
  x = seq(from = 1,to = 20, by = 2),
  y = c("a","b"),               # NOTE: R recycles vectors. This is a common theme.
  row.names = LETTERS[1:10],
  stringsAsFactors = TRUE       # This is the default behavior!!!
)
d.f

# Add a couple more vectors
d.f = cbind(
  d.f,
  z = rep(letters[3:4], each=5),
  w = rep(letters[5:6], times=5)
)
d.f

# Change to names
names(d.f) = paste("x",1:4,sep="")  # NOTE: We are recycling vectors again...
                                    # "x" is a vector of length 1

# Use backquotes to put illegal characters where they don't belong...
names(d.f)[1] = "Subject number"
d.f$`Subject number`

# Get prestored data.frame (d.f)
data()             # Get the list
data(mtcars)       # Make a promise
help(mtcars)       # Equivalent ?mtcars

# Get some basic information on the d.f
class(mtcars)
names(mtcars)
row.names(mtcars)
str(mtcars)

# Peek at first six rows and columns of d.f
head(mtcars)
tail(mtcars)

# Show dimensions of d.f
dim(mtcars)
nrow(mtcars)
ncol(mtcars)
length(mtcars)     # Remember, d.f is a list of column vectors

###############
# Indexing
###############

## The three main indexing operators are '[', '[[', and '$'

# Indices begin at 1
mtcars[0,0]        # Not what you wanted
mtcars[1,1]        # First row of first variable

# Some indexing removes parent class
str(mtcars[1,1])   # Atomic vector

# Just MPG
mtcars[ ,1]        # Blank will return all values
mtcars$mpg         # '$' notation
mtcars[[1]]        # '[[' operator will only return a single element
mtcars[1]          # Wait, this one is different! Attributes retained...
`[`(mtcars,1)      # All operators are actually functions

# Subsetting rows
mtcars[1,]         #Just the first observation
mtcars[1:10,]      #first ten rows
mtcars[1:10,10:11] #gears and carb
mtcars[grep("^Merc",row.names(mtcars)),] #Mercedes vehicles

# Subsetting with logic
mtcars[which(mtcars$mpg > 20),]
mtcars[mtcars$mpg > 20,]

# You can subset either with logical vector or index number
# Consider space use versus ease of coding
logical.vector = mtcars$mpg > 20
index.vector = which(mtcars$mpg > 20)

all.equal(
  mtcars[index.vector,],
  mtcars[logical.vector,]
)

###############
# Functions
###############

## The four most important concepts in R function writing/calling:
# 1. Lazy evaluation
# 2. Call-by-value
# 3. Lexical scoping
# 4. the dot-dot-dot (...) object

# Call the function without the parentheses to see the function definition
# e.g.,
my.function = function (x, y, eval=TRUE) {  # Define a simple function
  if (eval) x*y
}

my.function(5,6)                            # Execute the function
my.function                                 # Definition printed to console

# See more @:
# https://cran.r-project.org/doc/manuals/r-release/R-lang.html#Functions

###############
# Getting the most out of your vectors
###############

## (Taken mostly from R Inferno)

## Using vectorized operations to their fullest capacity is faster
n=10^4

# Slow...
system.time({
  vector <- integer(0)
  for (i in seq(1,n)) {
    vector <- c(vector,i)
  }
})

# Better...
system.time({
  vector <- integer(n)
  for (i in seq(1,n)) {
    vector[i] <- i
  }
})

# Best!
system.time(vector <- 1:n)

## The code is easier to write, too

# Slow and hard to read
lsum <- 0
for (i in seq(1,n))  {
  lsum <- lsum + log(i)
}
lsum

# Fast and easy to read
sum(log(1:n))

## Operations can be performed across elements of lists
# Slow
for (i in seq_along(mtcars)) {
  x[i] = mean(mtcars[,i])
  names(x)[i] = names(mtcars[i])
}
x

# Fast
lapply(mtcars, FUN=mean)  # Returns list
sapply(mtcars, FUN=mean)  # Returns vector when possible


###############
# Using packages
###############

# R's power comes in part from its extensive package library.
# R users have created [large integer] packages covering everything
# from bioinformatics to statistics, plotting and data mining.
# These packages can be accessed through the cran repository.
# Download/install them using your IDE or with the install.packages() function.

# Use library() or require().
# The biggest difference is that require() returns a logical value 
# to indicate success or failure to load.

print(library("this package does not exist"))  # Error
print(require("this package does not exist"))  # Error plus returns FALSE

## Using require() allows for (among other things)
## dynamic installation of packages
# if (!require(magrittr)) {
#   install.packages("magrittr")
#   library(magrittr)  # Not sure if install.packages() automatically loads too...
# }
# 
## Define function for loading multiple packages
## c/o stevenworthington github, ipak.R
## https://gist.github.com/stevenworthington/3178163
ipak <- function(pkg){
  new.pkg <- pkg[!(pkg %in% installed.packages()[ ,"Package"])]
  if (length(new.pkg)) 
    install.packages(new.pkg, dependencies = TRUE)
  sapply(pkg, require, character.only = TRUE)
}

# ipak("magrittr","dplyr","ggplot2")

###############
# End of demo
###############

## NEXT TIME: The joy of magrittr, or...
# 
#           %>%
#   ceci n'est pas une pipe
# 

# Thank you