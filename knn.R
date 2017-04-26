
####### Packages needed #######
####### Tested with R = 3.3.1 & 3.4.0 #######

library(downloader)
library(text2vec)
library(SnowballC)
library(base64enc)
library(stringi)
library(XML)


####### Pre-processing and training #######

source('downloadData.R'); # Download and extract training data.
source('importData.R'); # Import training dataset.
source('training.R'); # Find optimal parameters and assess accuracy.


####### Classify new emails #######
# This step can be run multiple times after the training stage without
# having to re-run everything.

source('predict.R'); # Predict emails with optimal parameters.