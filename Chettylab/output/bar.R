"
Using R to plot five best and worst CZ
"
rm(list=ls())  #clear all
library(ggplot2)  
setwd("H:/stata/Chettylab/output")   #set working directory
dta <- read.csv("Rgraph.csv", header=TRUE,sep=",")
dta$no_rank=factor(dta$no_rank)  #factor no_rank

#Grapgh
ggplot(dta,aes(x=no_rank,y=dif_rank))+
  geom_bar(aes(fill=last_five), stat="identity")+
  scale_fill_gradient(high="blue4",low="red4")+
  scale_x_discrete(labels=dta$cz_name_state)+
  labs(x="Commuting Zone",y="Diiference from National Mean")+
  coord_flip()+
  theme_bw()+
  theme(plot.title=element_text(size=18),
        panel.border=element_blank(),
        axis.title=element_text(size=18),
        axis.ticks=element_blank(),
        axis.text=element_text(size=14),
        panel.grid=element_blank(),
        legend.position="none")
ggsave(file="Rplot.pdf", width = 40, height = 24)