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
#   TITLE:   Machine Learning: Building and assessing classifiers to 
#            predict credit defaults
#           
#   AUTHOR:  Paul Egeler and Jordan Stewart
#
#   CONTACT: paulegeler .at. gmail .dot. com  
#   
#   DATE:    16 Aug 2016
#   
#   PURPOSE: Data science is loosely defined as the interdisciplinary field 
#            in which practitioners extract information and knowledge from data. 
#            Machine learning is a sub-discipline of data science which uses instances 
#            with known outcomes to make predictions about future instances. We will 
#            use computational and statistical models to make predictions on real-world 
#            data--namely whether or not an individual poses a risk for credit default. 
# 
#   ACKNOWLEDGEMENTS: 
#
#            Thanks to Tashi Reigle and Paul Lacki for humoring my questions!
#
###############################################################################
#
#   Resources:
#
#     Dataset care of UCI Machine Learning Repository
#     default of credit card clients Data Set
#     http://archive.ics.uci.edu/ml/datasets/default+of+credit+card+clients#
#     Retrieved 3 Aug 2016, modified for easy read-in
#     
#     Predictive Modeling with R and the caret Package
#     useR! 2013
#     Max Kuhn, PhD
#     https://www.r-project.org/nosvn/conferences/useR-2013/Tutorials/kuhn/user_caret_2up.pdf
#     
#     Applied Predictive Modeling
#     Max Kuhn, Kjell Johnson
#     2013 Springer, NYC
#
#
###############################################################################

###############
# Loading Packages
###############

# First I want to ask you some questions:
library(tcltk2)

# Message box to ask if it's OK to install packages on your computer
OK2Install = tkmessageBox(
  title = "Question! Pregunta!",
  message = paste("Install required packages? \r\n\n",
                  "Saying YES will  load all packages used in this demo.",
                  "Any package that is not previously installed will be",
                  "installed automatically. \r\n",
                  "Saying NO will attempt to load, but will not install."
                  ),
  icon = "question", 
  type = "yesno"
)

# Now that we've gotten that out of the way...
# This is the list of libraries we'll use:
libs = c(
  "magrittr", 
  "scales",
  "rpart",
  "randomForest",
  "data.table",
  "nnet",
  "dplyr",
  "caret",
  "pROC",
  "e1071"
  )

# Automated loading of libraries
if (tclvalue(OK2Install) == "yes") {
## Define function for loading multiple packages
## c/o stevenworthington github, ipak.R
## https://gist.github.com/stevenworthington/3178163
  ipak <- function(pkg){
    new.pkg <- pkg[!(pkg %in% installed.packages()[ ,"Package"])]
    if (length(new.pkg)) 
      install.packages(new.pkg, dependencies = TRUE)
    sapply(pkg, require, character.only = TRUE)
  }
  
  ipak(libs)
} else {
  sapply(libs,require, character.only = TRUE)
}

#rm(list=c("OK2Install","libs"))

###############
# Loading the Data
###############

d.f = read.csv(
  #"~/R/2016-08-16-MachineLearning.csv",
  "http://www.neuron0.net/R/2016-08-16-MachineLearning.csv",
  #nrows=1000,
  row.names=1,
  colClasses = c(
    rep("integer",2),
    rep("factor",3),
    rep("integer",19),
    "factor"
    )
)

# Checking the sturcture of the d.f
str(d.f)
names(d.f)

# Peek at first six rows and columns of d.f
head(d.f)
tail(d.f)

# Show dimensions of d.f
dim(d.f)

###############
# Cleaning the Data
###############

# I really don't like those names in all caps...
names(d.f) = tolower(names(d.f))

# And we should probably make naming Google compliant...
names(d.f) = gsub("_",".",names(d.f))

# Give readable names to factors
# Note that some levels were coded incorrectly in the source data,
# hence the need for the factor() function.
d.f = within(d.f,{
  levels(sex) = c("M","F")
  education = factor(education, levels = 1:4, labels = c("Grad School","University","High School","Other"))
  marriage = factor(marriage, levels = 1:3, labels = c("Married","Single","Other"))
  levels(response) = c("No Default","Default")
})

# Check our work
head(d.f[c(2,3,4,24)])  # Good.
tail(d.f["factor" == sapply(d.f,class)]) # Another way with more pizazz.

# For ease of reference, we make indices for related variables
vars = list(
  # each of the month-over-month 
  ontime = grep("pay.[0-9]",names(d.f)),
  bill = grep("bill.amt[0-9]",names(d.f)),
  pay = grep("pay.amt[0-9]",names(d.f)),
  # class versus numeric
  numeric = which("factor" != sapply(d.f,class)),
  class = which("factor" == sapply(d.f,class) & "response" != names(d.f)),
  # response variable
  response = 24
)

# And pay.[0-9] with pay.amt[0-9] in the same data set is confusing
names(d.f)[vars$ontime] = sub("pay","ontime",names(d.f[vars$ontime]))


###############
# Exploring the Data
###############

# Any missing?
colSums(is.na(d.f))
which(rowSums(is.na(d.f)) > 0)

# We can do informative missing, but I'm just going to do listwise deletion
d.f %<>% filter(.,rowSums(is.na(.)) == 0)

# Summary is an excellent function
summary(d.f)

# Proportion of "Default"s
table(d.f$response)
sum(d.f$response == "Default") / nrow(d.f)

# Looking into the distribution of quantitative variables
# Financial data tends to be log-normally distributed
sapply(d.f[vars$numeric] %>% sample_n(500), hist, breaks = "fd")
#abline(v = 0, col = "#ff0000")

# I am going to do a log transform to get us closer to normal.
# This can help in accuracy, especially with smaller data sets.
# However, interpretation becomes harder...
d.f$limit.bal %<>% ifelse(. <= 0, 0, .) %>% add(1) %>% log
for (i in c(vars$bill,vars$pay)) {
  d.f[,i] %<>% ifelse(. <= 0, 0, .) %>% add(1) %>% log
}

# How does the distribution look now?
sapply(d.f[vars$numeric] %>% sample_n(500), hist, breaks = "fd")

## Look at relationship between target variable and inputs
# First, numeric. I'm just using a t test to get a basic sense
# of whether there is association

num.p.vals = numeric(length(vars$numeric))
names(num.p.vals) = d.f[vars$numeric] %>% names
for (i in seq_along(vars$numeric)) {
  num.p.vals[i] = t.test(d.f[,vars$numeric[i]]~d.f$response)$p.value
}

num.p.vals %>% sort %>% round(4)
num.p.vals[num.p.vals > 0.15]

#####
# All num vars appear to be highly associated with response
#####

# Now lets do the same with class variables
class.p.vals = numeric(length(vars$class))
names(class.p.vals) = d.f[vars$class] %>% names
for (i in seq_along(vars$class)) {
  tmp.table = table(d.f[,vars$class[i]],d.f$response)
  print(tmp.table)
  class.p.vals[i] = chisq.test(tmp.table)$p.value
}

class.p.vals %>% sort # %>% round(4)
class.p.vals[class.p.vals > 0.15]

####
# All class vars appear to be highly associated with response
####

## Looking for multicollinearity between quantitative variables
#highly.corr = findCorrelation(cor(d.f[setdiff(vars$numeric,vars$bill)]), cutoff = 0.75)
highly.corr = findCorrelation(cor(d.f[vars$numeric]), cutoff = 0.75)
names(d.f[vars$numeric[highly.corr]])
cor(d.f[vars$numeric[highly.corr]])

# For bill amount and  ontime variables,
# we will want to do a variable reduction technique

# Oddly, payment amount does not seem to be self-correlated...
cor(d.f[vars$pay])

# Let's plot the relationship between billing amount and ontime.
plot(
  x = rowMeans(d.f[vars$ontime]), 
  y = rowMeans(d.f[vars$bill]), 
  pch = 16, 
  col = scales::alpha(as.integer(d.f$response),0.15)
)

###############
# Dimension Reduction and Data Transformation
###############

## Reducing Ontime variables
max.late = apply(d.f[vars$ontime], MARGIN = 1, FUN = max)
t.test(max.late ~ d.f$response)
table(max.late,d.f$response)

# Considered binning here.
# What do you think?
# max.late.bin = ifelse(max.late <= 2, max.late, "3+") %>% factor
# table(max.late.bin,d.f$response)
# chisq.test(max.late.bin,d.f$response)

hist(as.matrix(d.f[vars$ontime]))

d.f %<>% cbind(max.late) 

head(d.f)

# Which variables are we going to keep?
#vars$inputs = c(1:2,5,vars$pay,vars$bill[1],25)
vars$inputs = c(1:5,vars$pay,vars$bill[1],25)

# Quick check for multicollinearity
cor(d.f[vars$inputs[-2:-4]]) %>%
  findCorrelation(cutoff = 0.75) # Good to go.

###############
# Sampling/Partitioning
###############

## Partition d.f into 70/30 split--train/test
# Ideally, this is done right after reading in the data
# I held off because any transformations done to training
# set would need to be done to test set as well. Saving this
# partition step until after transformations IS WRONG, but it
# makes my life easier since I don't have to come back and
# transform the test set later.

set.seed(999)

grp.assign = sample(
	c("train", "test"), 
	nrow(d.f), 
	replace=TRUE, 
	prob = c(0.7, 0.3)
	)

# Check out work
table(grp.assign)

## Create partitioned dataset
d.f.tt = split(
  data.frame(
    d.f[vars$inputs],
    d.f[vars$response]
    ),
  grp.assign
  )

# Look at proportion of events in trainig data set
# We will use this as the probability cutoff when scoring new data
prior = sum(d.f.tt$train$response == "Default") / nrow(d.f.tt$train)

###############
# Logistic Regression
###############

# Call a GLM (Logistic regression is a type of Generalized Linear Model)
glm.model = glm(response ~ ., 
                data = d.f.tt$train, 
                family = "binomial", 
                na.action = na.omit
                ) %>% step(direction = "both")

glm.model
plot(glm.model)
anova(glm.model)

# How do the probabilities shake out?
glm.model$fitted.values %>% hist(breaks = "fd")

# Now lets score previously unseen data
# This was not used in modeling! These are completely novel cases!
d.f.tt$test$glm.pred.prob = predict.glm(glm.model, d.f.tt$test, type = "response")

d.f.tt$test$glm.pred.class = ifelse(d.f.tt$test$glm.pred.prob >= prior,
                                    "Default",
                                    "No Default") %>%
  factor(levels = c("No Default","Default"))


###############
# randomForest
###############

# CART data uses very few assumptions
# Therefore, it does not need to be transformed prior to fitting.
# In addition, due to randomForest's feature bagging, dimension
# reduction is done as part of the fitting process.

# First, a simple classification chart for motivational purposes

tree.model = rpart(response ~ ., d.f.tt$train)
plot(tree.model)
text(tree.model,use.n = TRUE)

# Save our scores
d.f.tt$test %<>% cbind(
  .,
  tree.pred.prob = predict(tree.model, .)[,"Default"],
  tree.pred.class = predict(tree.model, ., type = "class")
)

# Now the randomForest call
rf.model = randomForest(response ~ ., data = d.f.tt$train, na.action = na.omit)
rf.model
str(rf.model)

rf.model$confusion
rf.model$importance

d.f.tt$test %<>% cbind(
  .,
  rf.pred.prob = predict(rf.model, ., type = "prob")[,"Default"],
  rf.pred.class = predict(rf.model, .)
)

head(d.f.tt$test)


###############
# Neural Net
###############

# We're going to have to scale the numerics for this step
# Therefore, I am making a new copy of the data.frame
d.f.ann = split(
  data.frame(
    d.f[vars$inputs],
    d.f[vars$response]
  ),
  grp.assign
)

# data.tables affect subsetting, so I'm switching back to data.frame
setDF(d.f.ann$train)
setDF(d.f.ann$test)

# For NNETs, numeric variables must be scaled
numeric.vars = sapply(d.f.ann$train, class) !="factor"

d.f.ann$train[numeric.vars] %<>% scale
d.f.ann$test[numeric.vars] %<>% scale

# Simple ANN with 5 hidden nodes
annFit = nnet(response ~ .,
              data = d.f.ann$train,
              size = 5,
              decay = 0.1,
              linout = FALSE,
              trace = FALSE,
              maxit = 500,
              MaxNWts = 5 * ((ncol(d.f.ann$train) + 1) + 5 + 1 )
)

# Now an average of (n = 5) ANN 
annFitAve = nnet(response ~ .,
                 data = d.f.ann$train,
                 size = 5,
                 decay = 0.1,
                 linout = FALSE,
                 trace = FALSE,
                 maxit = 500,
                 MaxNWts = 5 * ((ncol(d.f.ann$train) + 1) + 5 + 1 ),
                 repeats = 5
)

# Now let's score the test data
d.f.tt$test$ann.pred.prob = predict(annFit,d.f.ann$test)
d.f.tt$test$annAve.pred.prob = predict(annFitAve,d.f.ann$test)

d.f.tt$test$ann.pred.class = ifelse(d.f.tt$test$ann.pred.prob >= prior,
                                    "Default",
                                    "No Default") %>%
  factor(levels = c("No Default","Default"))

d.f.tt$test$annAve.pred.class = ifelse(d.f.tt$test$annAve.pred.prob >= prior,
                                    "Default",
                                    "No Default") %>%
  factor(levels = c("No Default","Default"))



###############
# Model Assessment
###############

## Confusion matrices

confusionMatrix(data = d.f.tt$test$rf.pred.class,
                reference = d.f.tt$test$response,
                positive = "Default"
)

## Sensitivity and Specificity
# Sensitivity = TP / (TP + FN)

sensitivity(data = d.f.tt$test$rf.pred.class,
            reference = d.f.tt$test$response,
            positive = "Default"
)

# Specificity = TN / (TN + FP)

specificity(data = d.f.tt$test$rf.pred.class,
            reference = d.f.tt$test$response,
            negative = "No Default"
)

## Predictive value

posPredValue(data = d.f.tt$test$rf.pred.class,
             reference = d.f.tt$test$response,
             positive = "Default"
)

negPredValue(data = d.f.tt$test$rf.pred.class,
             reference = d.f.tt$test$response,
             negative = "No Default"
)

## The Receiver Operator Characteristic (ROC)
rf.rocCurve = with(d.f.tt$test, 
                roc(response = response,
                    predictor = rf.pred.prob,
                    levels = levels(response)
                )
)

rf.rocCurve                             # Print call
auc(rf.rocCurve)                        # Area under the curve (higher is better)
# ci.roc(rf.rocCurve)                   # Confidence interval (won't run)
plot(rf.rocCurve, legacy.axes = TRUE)   # Plot!

# Let's compare all methods explored today
tree.rocCurve = with(d.f.tt$test, 
                    roc(response = response,
                        predictor = tree.pred.prob,
                        levels = levels(response)
                    )
)

glm.rocCurve = with(d.f.tt$test, 
                roc(response = response,
                    predictor = glm.pred.prob,
                    levels = levels(response)
                )
)

ann.rocCurve = with(d.f.tt$test, 
                    roc(response = response,
                        predictor = as.numeric(ann.pred.prob),
                        levels = levels(response)
                    )
)

annAve.rocCurve = with(d.f.tt$test, 
                    roc(response = response,
                        predictor = as.numeric(annAve.pred.prob),
                        levels = levels(response)
                    )
)

# Plot of all ROC curves on top of each other
plot(tree.rocCurve,   legacy.axes = TRUE, add = TRUE, col = "#808080") # Gray
plot(glm.rocCurve,    legacy.axes = TRUE, add = TRUE, col = "#FF0000") # Red
plot(ann.rocCurve,    legacy.axes = TRUE, add = TRUE, col = "#00FF80") # Teal
plot(annAve.rocCurve, legacy.axes = TRUE, add = TRUE, col = "#0000FF") # Blue

# Sorted list of AUC (higher is better)
sapply(mget(ls(pattern = ".rocCurve$")), auc) %>% sort


###############################################################################
#### End of presentation
#### Thank you!
####
####Next time, bagging, boosting, and jackknifing--resampling to improve accuracy
###############################################################################

## Appendix

###############
# Dimension Reduction and Data Transformation
#  Motivational Code
###############

####################################################################
# Looks like we're going to have too many variables to model
# and major multicollinearity between several variables.
#
# There are several ways to reduce the number of variables
# (dimension reduction), which fit into two general categories: 
# feature selection (i.e., filtering by methods such as chi-square 
# or correlation coefficient) and feature extraction (i.e., transforming 
# multiple dimensions of data into fewer dimensions such 
# as via principal component analysis). 
# 
# Some examples:
#   
#    FEATURE SELECTION
#       Correlation coefficient
#       Chi-squared
#       randomForest
#       Gradient boosting
#       Combinations of two or more
# 
#    FEATURE EXTRACTION
#       Variable clustering
#       Principal components
#
# In many "BIG DATA" applications, you may have more variables than can be 
# considered manually. In those cases, it is all the more important to use
# systematic approaches to winnow down potential leads. That said, one should
# still manually inspect the data--lest you find ghosts.
#
# Principal component analysis (PCA) is a form of feature extraction.
# But it can also be used for exploratory analysis.
# Out of the box, this data does not meet the multivariate normal assumption.
# Careful when using non-normal data--some techniques are more sensitve than others.
#
# Remember, transformations should be applied BEFORE partitioning the data
# into test/train.
# Transform the test set using the same algorithm as the training set.
# Essentially, you are "scoring" the test set from the training set when
# transforming, much like you do for scoring the response
#
####################################################################


# Let's look at the relationship of all the highly collinear 
# quantitative variables using PCA
demo.data = split(d.f[vars$numeric],grp.assign)

demo.data$train %<>% sample_n(1500)
demo.data$test %<>% sample_n(500)

highly.corr = findCorrelation(cor(demo.data$train), cutoff = 0.65)
names(demo.data$train[highly.corr])
PC = princomp(demo.data$train[highly.corr],cor=TRUE)


print(PC)     # Standard print
summary(PC)   # Detail
str(PC)       # Structure of object
plot(PC)      # Scree plot
biplot(PC)    # Biplot

# In this case, we could take the first one or two principal components and capture
# most of the variation in the data, reducing 9 dimensions to 2.

# These vectors can now be used in predictive model building
PC$scores[,1:2]

# And these vectors can be used to score new data
predict(PC, demo.data$test)[,1:2]




  





