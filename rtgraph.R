library(twitteR)
library(igraph)

auth <- readLines(con = "./auth.txt", warn = F, skipNul = T) %>%
  gsub("[[:space:]]", "", .)

# Lines in auth.txt file are organized as follows:
# [1] Consumer key
# [2] Consumer secret
# [3] Access token
# [4] Access secret

options(httr_oauth_cache = T)
setup_twitter_oauth(auth[1], auth[2], auth[3], auth[4])

if(interactive()) {
  tweetID <- readline("Tweet number: ")
  } else {
    cat("Tweet number: ")
    tweetID <- readLines(con = "stdin", n = 1)
}

tweetTweet  <- tryCatch(showStatus(tweetID),
                        error = function(e) {
                          stop("Tweet Not Found")
                          }
                        )

# Data Collection -------------------------------------------------------------

tweetAuthor <- getUser(tweetTweet$screenName)
rTweeters   <- retweeters(tweetID, n = 100)

# Collecting author's followers
authorFollowerIDs <- tweetAuthor$getFollowerIDs(retryOnRateLimit = 180)

# Collecting retweeters' followers
retweetersGraph <- data.frame(Source = character(0),
                              Target = character(0)
                              )

for (i in 1:length(rTweeters)) {
  userName <- tryCatch(
    getUser(rTweeters[i]),
    error = function(e) NULL
    )
  if(is.null(userName)) next
  
  cat("Collecting followers from user", userName$name, "...\n")
  
  followersRate <- getCurRateLimitInfo("followers")
  if(any(followersRate$remaining == 0)) {
    print("Rate limited ... resuming again in 15 minutes")
    Sys.sleep(901)
  }
  
  userFoll <- userName$getFollowers(retryOnRateLimit = 60) %>%
    names()
  userNet <- data.frame(Source = rep(userName$id,
                                     length(userFoll)),
                        Target = userFoll)
  
  retweetersGraph <- rbind.data.frame(retweetersGraph,
                                      userNet)
}

# Format and save entire, original edge graph, just in case
retweetersGraph$Source <- as.character(retweetersGraph$Source)
retweetersGraph$Target <- as.character(retweetersGraph$Target)
save(retweetersGraph,
     file = paste(as.character(tweetID), "RTsGraph.RData", sep = "_")
     )

# Cleaning up a bit
rTweetersAll <- rTweeters[rTweeters %in% retweetersGraph$Source]
rTweetersFol <- rTweetersAll[rTweetersAll %in% authorFollowerIDs]
selectVec    <- retweetersGraph$Target %in% rTweetersAll

# Final edge graph dataset
retweetersEdge <- data.frame(Source = rep(as.numeric(tweetAuthor$id), 
                                          length(rTweetersFol)),
                             Target = as.numeric(rTweetersFol)
                             )
retweetersEdge <- rbind.data.frame(retweetersEdge,
                                   retweetersGraph[selectVec, ]
                                   )

# Node graph dataset
retweetersNode <- c(tweetAuthor$id, 
                    rTweetersAll) %>%
  unique() %>% as.data.frame()
colnames(retweetersNode) <- "ID"

retweetersNode$Following <- ifelse(retweetersNode$ID == tweetAuthor$id,
                                   "Author",
                                   ifelse(retweetersNode$ID %in% rTweetersFol,
                                          "Yes", "No")
                                   )

# Saving node and edge datasets
write.csv(retweetersEdge,
          paste(as.character(tweetID), "RTsEdgeGraph.csv", sep = "_"),
          row.names = F)
write.csv(retweetersNode,
          paste(as.character(tweetID), "RTsNodeGraph.csv", sep = "_"),
          row.names = F)

# Converting to igraph object and visualization -------------------------------

rtsNetwork <- graph_from_data_frame(d = retweetersEdge,
                                    vertices = retweetersNode)

V(rtsNetwork)$color <- ifelse(V(rtsNetwork)$Following == "Author",
                              "black",
                              ifelse(V(rtsNetwork)$Following == "Yes",
                                     "green",
                                     "red")
                              )

png(paste(as.character(tweetID), "RtGraph.png", sep = "-"), 
    width = 1024, height = 768)
plot(rtsNetwork, 
     vertex.label = NA, vertex.size = 5, 
     edge.arrow.size = .4)
dev.off()

# Save everything
save(list = ls(), 
     file = paste(as.character(tweetID), "rtData.RData", sep = "_")
     )

# To-do (sometime in the future) ----------------------------------------------

#    1. Collect more data for node attributes
#       (Follower count, timestamps, location, etc.)
#    2. ? ? ? 
#    3. Profit!
