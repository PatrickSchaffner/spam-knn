
####### Import emails to predict #######

test <- readMails('./TEST')
test <- as.data.frame(test)

####### Setup kNN classifier #######

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
train_docs <- itoken(as.vector(mails$text), preprocessor=tolower, tokenizer=tokenizer, ids=mails$id, progressbar=FALSE)
vocabulary <- create_vocabulary(train_docs)
vocabulary <- prune_vocabulary(vocabulary, term_count_min = 10, doc_proportion_max = 0.5)

# Vectorize training documents
vectorizer <- vocab_vectorizer(vocabulary)
train_docs <- create_dtm(train_docs, vectorizer) # Create document-terms-matrix.

# Transform to TF-IDF features
tfidf <- TfIdf$new()
train_docs <- fit_transform(train_docs, tfidf)
train_docs <- as.matrix(train_docs)


####### Extract features from test dataset #######

# Vectorizer test documents and transform to TF-IDF features
test_docs <- itoken(as.vector(test$text), preprocessor=tolower, tokenizer=tokenizer, ids=test$id, progressbar=FALSE)
test_docs <- create_dtm(test_docs, vectorizer) %>% transform(tfidf)
test_docs <- as.matrix(test_docs)


####### Predict #######

# Dimensions.
N.features <- dim(train_docs)[2]
N.train <- dim(train_docs)[1]
N.test <- dim(test_docs)[1]

# Classification
for (i in 1:N.test) {

    # Euclidean distance
    distance <- sqrt(rowSums((train_docs-matrix(rep(test_docs[i,],times=N.train),N.train,N.features,byrow=TRUE))^2))
    
    # Sort training documents by distance
    I <- sort(distance,decreasing=FALSE,index.return=TRUE)$ix
    
    # Get labels of nearest neighbors
    L <- mails$spam[I[1:k]]
    
    # Classify as spam if majority of neighbors is spam
    spam <- mean(as.numeric(L))>0.5
    
    # Output
    print(paste(test$id[i],spam))
    
}

