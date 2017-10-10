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
#   TITLE:   That was easy: create your own R packages in minutes with roxygen2
#           
#   AUTHOR:  Paul Egeler
#
#   CONTACT: paulegeler .at. gmail .dot. com  
#   
#   DATE:    20 Jun 2017
#   
#   PURPOSE: 
# 
# Creating personal packages is a great way to build your analytic toolbox
# and share code with co-workers, friends, classmates, or even THE WORLD!
#   
# This demo shows how to make a rudimentary package complete with R functions,
# data, and documentation. We will then install the package and try it out.
# Finally, we will show how to bundle up the package so it can be shared with
# others.
# 
#   LICENSE: 
#
# Released under GPL v2. AS IS. NO WARRANTY!!!
#
###############################################################################
#
#   Resources:
#
# CRAN: Creating R Packages
# https://cran.r-project.org/doc/manuals/R-exts.html#Creating-R-packages
# 
# R packages by Hadley Wickham
# http://r-pkgs.had.co.nz/intro.html
# 
# Hillary Parker
# https://hilaryparker.com/2014/04/29/writing-an-r-package-from-scratch/
# 
# roxygen2 vignettes  
# https://cran.r-project.org/web/packages/roxygen2/vignettes/
#
# Cheatsheet
# Help > Cheatsheets > Package Development with devtools
#
###############################################################################

# Installing and Loading Development Packages -----------------------------

ipak <- function(pkgs){
  
  new.pkgs <- pkgs[!(pkgs %in% installed.packages()[ ,"Package"])]
  
  if (length(new.pkgs)) {
    
    install.packages(new.pkgs, dependencies = TRUE)
    
  }
  
  sapply(pkgs, require, character.only = TRUE)
}

ipak(c("devtools", "roxygen2", "testthat", "knitr"))

rm(ipak)

# You should also install Rtools (WIN), XCode (Mac), or R development tools (Linux)
# http://cran.r-project.org/bin/windows/Rtools/

# Check to make sure we have everything we need
devtools::has_devel()

# Create a skeleton folder structure --------------------------------------

setwd("~/R")
devtools::create("pablo.del.palo")

# Make your package content and document it -------------------------------

# Next steps:
#  1. Go to the folder and change the 'DESCRIPTION' file
#  2. Put all function definitions in the 'R' folder
#  3. Put data in the 'data' folder
#  4. Document your work with the roxygen markdown laguage
#     (embedded in your code)

## devtools has functions to simplify most steps, for example:
# Include data in your environment
foo = c("foo","bar","baz")
devtools::use_data(foo, pkg = "pablo.del.palo")

# Include source code for creating other datasets
devtools::use_data_raw("pablo.del.palo")

# Include 'Imports' or 'Suggests' packages
devtools::use_package("tcltk", type = "Imports", "pablo.del.palo")
devtools::use_package("magrittr", type = "Imports", "pablo.del.palo")
devtools::use_package("maps", type = "Suggests", "pablo.del.palo")

# Install your package! ---------------------------------------------------

devtools::document("pablo.del.palo")
devtools::install("pablo.del.palo")

# Try it out! -------------------------------------------------------------

# Get help from your UDFs and datasets
?unemployment
?odds2prob

# Try some functions out
pis = seq(0,1,0.1)
pis
prob2odds(pis)

os = seq(0,4,0.5)
os
odds2prob(os)

varEntryDialog(letters[1:2], letters[1:2])

# Load in your dataset and and use it!
data(unemployment)
data(state.fips, package = "maps")

head(unemployment)
head(state.fips)

# Find the average unemployment rate by state
x = aggregate(
  unemployment[c("Unemp.Lvl","Labor.Force")], 
  list(fips = as.integer(unemployment[,"STATEFP"])), 
  FUN = sum
)
x$Unemp.Rate = 100 * x$Unemp.Lvl / x$Labor.Force

x = merge(
  x, 
  unique(state.fips[c("fips","abb")]), 
  by = "fips",
  all.x = TRUE
)

x$rank <- rank(x$Unemp.Rate)

x[order(x$Unemp.Rate),]


# Build your package to share with friends and co-workers! ----------------

devtools::build("pablo.del.palo") # Source - needs dev environment to install
devtools::build("pablo.del.palo", binary = TRUE) # Windows build - no dev env

# Your binary package can now be installed on Windows using:
install.packages(
  pkg = "./pablo.del.palo_0.0.0.9000.zip", 
  repos = NULL, 
  type = "binary"
)
