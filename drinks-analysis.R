library(tidytext)
library(dplyr)
library(ggplot2)
library(mice)
library(reshape2)

#note: descriptions truncated.  Could update scraper to get full descs

dat = read.csv('./klspirits.csv')
#Price to numeric, note that NAs represent "Price Hidden"- scraper could be changed to capture
dat$Price = gsub(' ','',dat$Price)
dat$Price = gsub('\\$','',dat$Price)
dat$Price = as.numeric(dat$Price)

dat$Desc = tolower(dat$Desc) #everything in Desc to lowercase
dat$Desc = gsub('[-]',' ',dat$Desc) #hyphen to space
dat$Desc = gsub('\'s','',dat$Desc) #apostrophe-s to null: turns ownership adjectives to proper nouns
dat$Desc = gsub('[^a-z ]','',dat$Desc) #nonletters/spaces to null

#straight-ahead sentiment analysis is likely appropriate for this kind of data: wineseller descriptions are unlikely to be sarcastic.  
#Possible hiccups: praise with harsh terms, like Riesling with petrol notes/'fiery' liquors.
#AFINN sentiments used as they have numerical scores.  Adjust for longer reviews?

score_sentiment = function(str){
  df = data.frame(strsplit(str,'\\s+'), stringsAsFactors = F)
  colnames(df) = 'word' 
  return(sum(inner_join(df, get_sentiments('afinn'))$score))
}

dat$sent = sapply(dat$Desc,score_sentiment)
dat$Desc[which.min(dat$sent)] #clearly sentiment analysis is imperfect: this is a good review

ggplot(dat, aes(x=Type, y=Price)) + geom_boxplot() #price by type
ggplot(dat, aes(x=sent, y=Price)) + geom_point() + geom_smooth(method='lm', se=F) #price by sentiment
ggplot(dat, aes(x=sent, y=Price, col=Type)) + geom_point() + geom_smooth(method = 'lm', se=F) #price by type and sentiment
#regression looks inappropriate
anova(lm(data = dat, Price ~ Type)) #ANOVA by type
TukeyHSD(aov(data = dat, Price ~ Type)) #Cognac and Armagnac

type_sentiment = function(str){ #uses NRC instead, gives typed sentiment
  df = data.frame(strsplit(str,'\\s+'), stringsAsFactors = F, 1)
  colnames(df) = c('word', 'co')
  preout = left_join(get_sentiments('nrc'), df) %>% 
    group_by(sentiment) %>%
    summarize(tot = sum(co, na.rm=T)) %>%
    t()
  out = t(data.frame(preout[-1,]))
  return(out)
}

sents = data.frame(t(sapply(dat$Desc,type_sentiment)))
sents = apply(sents, 2,function(x){as.numeric(as.character(x))})
colnames(sents) = sort(unique(get_sentiments('nrc')$sentiment))
dat = cbind(dat, sents)
summary(dat)

sapply(colnames(sents), function(x){dat$Desc[which.max(dat[[x]])]}) #most intense description by sentiment

plotdat = dat %>% 
  select(Name, Price, Type, anger, anticipation, disgust, fear, joy, negative, positive, sadness, surprise, trust)
plotdat = melt(plotdat, id.vars = c('Name', 'Price', 'Type'))
ggplot(plotdat, aes(x=value, y=Price, col=variable)) + geom_jitter() + geom_smooth(method = 'lm', se=F) #again no apparent relationship between sentiment and price

#missing prices
#multiple imputation?  Probably not appropriate given limited data.  Best to update scraper.

