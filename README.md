# RtGraph

This R script plots the relationships between an author of a tweet and the retweeters. 

The nodes represent the author and the retweeters, whereas the directed edges represent possible paths the tweet can "take" to reach a certain user.

## Requirements

RtGraph was written and tested using R 3.4.1 (Single Candle). The script requires the following packages: twitteR and igraph.

The consumer key, consumer secret, access token, and access secret for the Twitter API are required and need to be stored in the *auth.txt* file. Each string must be on a separate line and in the following order:
1. Consumer key
2. Consumer secret
3. Access token
4. Access secret

The file *auth.txt* must be in the same directory as the *rtgraph.R* file to access the API.

You can run the *rtgraph.R* script from an interactive session or from the terminal with Rscript:

```bash
Rscript rtGraph.R
```

## Input

The script asks for a tweet number (ID), which is found in the tweet's URL:

```html
https://twitter.com/username/status/[TweetID]
```

## Output

Saves the original edge graph with retweeters and all of their followers in an RData file. Also saves all objects into an RData file at the end.

Writes one CSV file with the edges of the graph and one CSV file with the nodes and their attributes.

The plot showing the connections between the author of a tweet and the retweeters is saved as a PNG file.

The file names begin with the tweet ID, so it is possible to collect data for several tweets without overwriting anything.

## Example

An example that shows the input and the output produced by this script is presented in [this article](https://velaco.github.io/rtgraph-example/).
