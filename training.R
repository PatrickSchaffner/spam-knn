
####### Splitting dataset #######

# Take 70% as training and 30% as test set.
I <- sample.int(length(mails$id),floor(length(mails$id)*0.7))
train <- mails[I,]
test <- mails[-I,]


####### Extract training features #######

# Text to word splitting, stemming and filter tokens.
tokenizer <- function(x) {
    tokens <- word_tokenizer(x) # Split text into words.
    tokens <- lapply(tokens,function(x) {
        x <- wordStem(x,language='en') # Apply snowball word stemming.
        x <- x[suppressWarnings(is.na(as.numeric(x)))] # Remove numbers.
        x <- x[!grepl('^_+$',x)] # Remove underscore-lines.
    })
    return(tokens)
}

# Build vocabulary
train_docs <- itoken(as.vector(train$text), preprocessor=tolower, tokenizer=tokenizer, ids=train$id, progressbar=FALSE)
vocabulary <- create_vocabulary(train_docs)
vocabulary <- prune_vocabulary(vocabulary, term_count_min = 10, doc_proportion_max = 0.5)

# Vectorize training documents
vectorizer <- vocab_vectorizer(vocabulary)
train_docs <- create_dtm(train_docs, vectorizer) # Create document-terms-matrix.

# Transform to TF-IDF features
tfidf <- TfIdf$new()
train_docs <- fit_transform(train_docs, tfidf)
train_docs <- as.matrix(train_docs)


####### Extract test features #######

# Vectorizer test documents and transform to TF-IDF features
test_docs <- itoken(as.vector(test$text), preprocessor=tolower, tokenizer=tokenizer, ids=test$id, progressbar=FALSE)
test_docs <- create_dtm(test_docs, vectorizer) %>% transform(tfidf)
test_docs <- as.matrix(test_docs)


####### Choose parameter k #######

# Values of k to test.
K <- 1:20;

# Dimensions.
N.features <- dim(train_docs)[2]
N.train <- dim(train_docs)[1]
N.test <- dim(test_docs)[1]

# Classification
spam <- logical(N.test*length(K))
dim(spam) <- c(N.test,length(K))
progress <- txtProgressBar(min=0,max=N.test,style=3)
for (i in 1:N.test) {

    # Euclidean distance
    distance <- sqrt(rowSums((train_docs-matrix(rep(test_docs[i,],times=N.train),N.train,N.features,byrow=TRUE))^2))
    # Sort training documents by distance
    I <- sort(distance,decreasing=FALSE,index.return=TRUE)$ix
    
    # Test different k values.
    for (j in 1:length(K)) {
        k <- K[j]
        L <- train$spam[I[1:k]] # Get labels of k nearest neighbors in training set.
        spam[i,j] <- mean(as.numeric(L))>0.5 # Classify as spam if majority of neighbors is spam.
    }
    
    setTxtProgressBar(progress,i)
}

# Compute accuracy.
acc <- colMeans(matrix(rep(test$spam,times=length(K)),N.test,length(K),byrow=FALSE)==spam)

# Get optimal k
plot(K,acc,type='l',xlab='k',ylab='Accuracy',main='Choosing k')
I = which(max(acc)==acc)
k <- K[I]; # Optimal k
print(paste0('Optimal k=',as.character(k),', accuracy=',as.character(acc[I]*100),'%'))
