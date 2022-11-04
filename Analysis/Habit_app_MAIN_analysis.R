#########################################################################################################
# R code for the habit app project (Gera et al.):
## Last modified by Rani on November 2022
## These analyses are based on the files produced by Habit_app_parse_data.ipynb and MBMF_parse_data.ipynb
#########################################################################################################

rm(list=ls())
# load packages (and install them if they are not installed)
if (!require("pacman")) install.packages("pacman")
pacman::p_load(devtools, lme4, lmerTest, rstan, ggplot2, plyr, rstudioapi, car, tidyr, Hmisc, Rfit, R2admb, glmmTMB, glmmADMB,
               plotly, flexmix, car, webshot, performance, sjPlot, afex, effectsize, ggpubr, scales, ggpmisc, ggExtra, dplyr)


# set directories and load files
setwd(dirname(rstudioapi::getActiveDocumentContext()$path))
figures_path  <- ('/Volumes/GoogleDrive/My Drive/Experiments/HAS_STUDY/MS/Figs')
habit_app_data <- 'data/extracted_data/all_data_for_R.csv'

# get and organize the data:
app_data = read.csv(habit_app_data, header=T)
# add training_length:
app_data[app_data$group=='short_training','training_length'] = 'short'
app_data[app_data$group!='short_training','training_length'] = 'long'

# separate groups (for some analyses)
short = subset(app_data, training_length=="short")
long = subset(app_data, training_length=="long")

# separate groups (for some analyses)
short_training = subset(app_data, group=="short_training")
long_training = subset(app_data, group=="long_training")
long_training_par = subset(app_data, group=="long_training_parallel_manipulations")


###############################################################################
####               MANIPULATION CHECK - ANALYSIS #1                        ####
###############################################################################

consumption = app_data[c('subID','cave_gold_still_valued','cave_gold_devaluation','cave_gold_still_valued_post_deval','devaluation','group','training_length')]
consumption$group = as.factor(consumption$group)
consumption$training_length = as.factor(consumption$training_length)
colnames(consumption)[2:4] = c('gold_pre_val','gold_deval','gold_post_val')
consumption = within(consumption, group <- relevel(group, ref = 'short_training'))
consumption = within(consumption, training_length <- relevel(training_length, ref = 'short'))
consumption[,'gold_mean_val'] = rowMeans(consumption[,c('gold_pre_val', 'gold_post_val')], na.rm=TRUE)

consumption1 = gather(consumption, manipulation, gold, c('gold_mean_val','gold_deval'), factor_key=TRUE)
consumption1 = within(consumption1, manipulation <- relevel(manipulation, ref = 'gold_mean_val'))
consumption1 = within(consumption1, group <- relevel(group, ref = 'short_training'))
consumption1 = within(consumption1, training_length <- relevel(training_length, ref = 'short'))

# t-test across all
t.test(consumption$gold_mean_val,consumption$gold_deval, paired = T)

# Anova with group and manipulation type:
summary(consumption_m <- aov_car(gold ~ group*manipulation + Error (subID/manipulation), data = consumption1))
omega_squared(consumption_m)

# --------- Plot:
consumption1$group   <- dplyr::recode(consumption1$group, "short_training" = "Short training",
                                      "long_training" = "Extensive training",
                                      "long_training_parallel_manipulations" = "Extensive training\n(w/parallel manipulations)")

p <- ggplot(consumption1, aes(x = manipulation, y = gold, fill=manipulation, color = manipulation)) +
  geom_point(alpha = .2, position = position_jitterdodge(jitter.width = .5, jitter.height = 0)) +
  geom_line(data = consumption1, aes(group = subID, y = gold, color = manipulation), alpha = .2, size = 0.3, color='gray') +
  geom_bar(alpha=0.1, stat = "summary", fun = "mean") +
  stat_summary(fun.data = mean_se, geom = "errorbar", width=.2) +
  stat_compare_means(label = "p.signif", paired = TRUE, method = "t.test",comparisons = list(c('gold_mean_val','gold_deval')),
                     label.y = 14.7, symnum.args = list(cutpoints = c(0, 0.0001, 0.001, 0.01, 0.05, 1), symbols = c("***", "***", "**", "*", "ns")),
                     tip.length=0, size = 7, vjust=0.45) + # method.args = list(alternative = "greater")
  scale_y_continuous(breaks= pretty_breaks()) +
  ylab('# Gold piles collceted')+
  xlab('Outcome state') +
  facet_grid(.~group) +
  scale_x_discrete(drop = FALSE, labels=c("gold_mean_val" = "Valued", "gold_deval" = "Devalued")) +
  scale_fill_manual(values=c("slateblue", "darkorange3")) + scale_color_manual(values=c("slateblue", "darkorange3"))

pp <- p + theme_light(base_size = 14, base_family = "Helvetica")+
  theme(strip.text.x = element_text(size = 16, face = "bold"),
        strip.text.y = element_text(size = 16, face = "bold"),
        strip.text = element_text(colour = 'black'),
        strip.background = element_rect(color="white", fill="white", linetype="solid"),
        axis.text.x = element_text(face="bold", size=12),
        axis.ticks.x = element_blank(),
        #legend.box.background = element_blank(),
        legend.position="none",
        panel.grid.minor = element_blank(),
        panel.grid.major = element_line(color="gray", size=0.05),
        axis.title.x = element_text(size = 14, face = "bold"),
        axis.title.y = element_text(size = 14, face = "bold"))

pp

ggsave(file.path(figures_path,'Manipulation-check_Cave.tiff'), pp, dpi = 100)


###############################################################################
####               MANIPULATION CHECK - ANALYSIS #2                        ####
###############################################################################

consumption2 = app_data[c('subID','still_valued','devaluation','still_valued_post_deval','mean_still_valued','group','training_length')]
consumption2$group = as.factor(consumption2$group)
consumption2$training_length = as.factor(consumption2$training_length)
colnames(consumption2)[2:5] = c('pre_val','deval','post_val','mean_val')
consumption2[c('pre_val','deval','post_val')] = consumption2[c('pre_val','deval','post_val')]/rowSums(consumption2[c('pre_val','deval','post_val')]) # get proportions
consumption2[apply(is.na(consumption2[c('pre_val','deval','post_val')]), 1, all), c('pre_val','deval','post_val')] = 0 # make 0 those withh all days with zero
consumption2[c('pre_val','deval','post_val')] = sqrt(consumption2[c('pre_val','deval','post_val')])

# t-test across all
t.test(consumption2$post_val,consumption2$deval, paired = T)
# in each group separately
t.test(consumption2[consumption2$group=='short_training','post_val'],consumption2[consumption2$group=='short_training','deval'], paired = T)
t.test(consumption2[consumption2$group=='long_training','post_val'],consumption2[consumption2$group=='long_training','deval'], paired = T)
t.test(consumption2[consumption2$group=='long_training_parallel_manipulations','post_val'],consumption2[consumption2$group=='long_training_parallel_manipulations','deval'], paired = T)

# --------- Plot:
consumption2_1 = gather(consumption2, manipulation, entries, deval:post_val, factor_key=TRUE)
consumption2_1 = within(consumption2_1, manipulation <- relevel(manipulation, ref = 'deval'))
consumption2_1 = within(consumption2_1, group <- relevel(group, ref = 'short_training'))
consumption2_1$group   <- dplyr::recode(consumption2_1$group, "short_training" = "Short training",
                                      "long_training" = "Extensive training",
                                      "long_training_parallel_manipulations" = "Extensive training\n(w/parallel manipulations)")

p <- ggplot(consumption2_1, aes(x = manipulation, y = entries, fill=manipulation, color = manipulation)) +
  geom_point(alpha = .2, position = position_jitterdodge(jitter.width = .5, jitter.height = 0)) +
  geom_line(data = consumption2_1, aes(group = subID, y = entries, color = manipulation), alpha = .2, size = 0.3, color='gray') +
  geom_boxplot(alpha=0.3,outlier.alpha =0) +
  stat_compare_means(label = "p.signif", paired = TRUE, method = "t.test",comparisons = list(c('deval','post_val')),
                     symnum.args = list(cutpoints = c(0, 0.0001, 0.001, 0.01, 0.05, 1), symbols = c("***", "***", "**", "*", "ns")),
                     tip.length=0, size = 7, vjust=0.45) + # method.args = list(alternative = "greater")
  scale_y_continuous(breaks= pretty_breaks()) +
  ylab('Square root of entry porp.')+
  xlab('Outcome state') +
  facet_grid(.~group) +
  scale_x_discrete(drop = FALSE, labels=c("post_val" = "Value\nregained", "deval" = "Devalued")) +
  scale_fill_manual(values=c("slateblue", "darkorange3")) + scale_color_manual(values=c("slateblue", "darkorange3"))

pp <- p + theme_light(base_size = 14, base_family = "Helvetica")+
  theme(strip.text.x = element_text(size = 14, face = "bold"),
        strip.text.y = element_text(size = 14, face = "bold"),
        strip.text = element_text(colour = 'black'),
        strip.background = element_rect(color="white", fill="white", linetype="solid"),
        axis.text.x = element_text(face="bold", size=12),
        axis.ticks.x = element_blank(),
        #legend.box.background = element_blank(),
        legend.position="none",
        panel.grid.minor = element_blank(),
        panel.grid.major = element_line(color="gray", size=0.05),
        axis.title.x = element_text(size = 14, face = "bold"),
        axis.title.y = element_text(size = 14, face = "bold"),
        aspect.ratio=2)

pp

ggsave(file.path(figures_path,'Supp-X-Manipulation_check2_bounce_back.tiff'), pp, dpi = 100)



####################################################################################################################################
####################            Main Hypothesis (of Habit formatio as a function of training duration)           ###################
####################################################################################################################################

main = app_data[c('subID','still_valued','devaluation','still_valued_post_deval','mean_still_valued','group','training_length')]
main$group = as.factor(main$group)
main$training_length = as.factor(main$training_length)
colnames(main)[2:5] = c('pre_val','deval','post_val','mean_val')
main = within(main, group <- relevel(group, ref = 'short_training'))
main = within(main, training_length <- relevel(training_length, ref = 'short'))

main1 = gather(main, manipulation, entries, pre_val:post_val, factor_key=TRUE)
main1 = within(main1, manipulation <- relevel(manipulation, ref = 'pre_val'))
main1 = within(main1, group <- relevel(group, ref = 'short_training'))
main1 = within(main1, training_length <- relevel(training_length, ref = 'short'))

#### Functions to test and adjust Poisson with OVER/UNDERDISPERSSION (http://bbolker.github.io/mixedmodels-misc/glmmFAQ.html#overdispersion)
overdisp_fun <- function(model) {
  rdf <- df.residual(model)
  rp <- residuals(model,type="pearson")
  Pearson.chisq <- sum(rp^2)
  prat <- Pearson.chisq/rdf
  pval <- pchisq(Pearson.chisq, df=rdf, lower.tail=FALSE)
  #pval <- pchisq(Pearson.chisq, df=rdf, lower.tail=TRUE)
  c(chisq=Pearson.chisq,ratio=prat,rdf=rdf,p=pval)
}
quasi_table <- function(model,ctab=coef(summary(model)),
                        phi=overdisp_fun(model)["ratio"]) {
  qctab <- within(as.data.frame(ctab),
                  {   `Std. Error` <- `Std. Error`*sqrt(phi)
                  `z value` <- Estimate/`Std. Error`
                  `Pr(>|z|)` <- 2*pnorm(abs(`z value`), lower.tail=FALSE)
                  })
  return(qctab)
}

# This was the model we originally conceptualize:
# m1 = (glmer(entries ~ manipulation*group + (1+manipulation|subID), data=main1, family = poisson, control=glmerControl(optimizer="bobyqa",optCtrl=list(maxfun=2e5))))
# BUT as there is one observation per cell when considering both the group and the manipulation factors
# only a random intercept should be use, i.e., a random intercept model is the right one to use. 

# Running the mixed-model Poisson model:
m1 = (glmer(entries ~ manipulation*group + (1|subID), data=main1, family = poisson, control=glmerControl(optimizer="bobyqa",optCtrl=list(maxfun=2e5))))

overdisp_fun(m1) # The data is largely OVERDISPERSED (chi square, p<0.001) ## note: "For Poisson models, the overdispersion test is based on 'the code from Gelman and Hill (2007), page 115.'Gelman, A., & Hill, J. (2007). Data analysis using regression and multilevel/hierarchical models. Cambridge; New York: Cambridge University Press."
check_overdispersion(m1)
#printCoefmat(quasi_table(m1),digits=3); For lack of better things to do this is what we would have done in the case of UNDERdispersion, but for overdisperssion there are better alternatives.

# We then tested which of three alternative methods would best fit our data, using Leave-one-out cross-validation (LOOCV).
# We tested an  OLRE (observation-level random effects), in which an "artificial" random effect is added for each observation, negative binomial with a quasi-poisson parameterization σ2=ϕμ, ϕ>1 (NB1) and negative binomial with the classic parameterization with σ2=μ(1+μ/k) (“NB2” in Hardin and Hilbe’s terminology).
# * OLRE - ref: Elston DA, Moss R, Bouliner T, Arrowsmith C, Lambin X. 2001. Analysis of aggregation, a worked example: number of ticks on red grouse. Parasitology 122:563-569
# * nbinom1 and nbinom2 ref: J. W. Hardin and J. M. Hilbe. Generalized Linear Models and Extensions, 2007. [p380]
main1$obs<-seq(nrow(main1)) # add the a unique number per observation for the OLRE
squaredErrors_nbinom1  <- c()
squaredErrors_nbinom2 <- c()
squaredErrors_OLRE <- c()
for (i in 1:length(unique(main1$subID))){
  print(main1$subID[i])
  # Create training and test sets for this iteration
  training_set <- main1[main1$subID != main1$subID[i],]
  testing_set <- main1[main1$subID == main1$subID[i],]
  # Train mixed effects model on training set
  model <-  glmmTMB(entries ~ manipulation*group + (1|subID), data=training_set, family = "nbinom1")
  model2 <- glmmTMB(entries ~ manipulation*group + (1|subID), data=training_set, family = "nbinom2")
  model3 <- glmmTMB(entries ~ manipulation*group + (1|subID)+(1|obs), data=training_set, family = "poisson")
  ## Test model
  # Predict the dependent variable in the testing_set with the trained model
  predicted  <- predict(model,  testing_set, allow.new.levels = TRUE)
  predicted2 <- predict(model2, testing_set, allow.new.levels = TRUE)
  predicted3 <- predict(model3, testing_set, allow.new.levels = TRUE)
  # Calculate the squared errores for each of the model:
  squaredErrors_nbinom1[(length(squaredErrors_nbinom1 )+1):(length(squaredErrors_nbinom1 )+3)] = (exp(predicted)-testing_set[['entries']])^2
  squaredErrors_nbinom2[(length(squaredErrors_nbinom2)+1):(length(squaredErrors_nbinom2)+3)] = (exp(predicted2)-testing_set[['entries']])^2
  squaredErrors_OLRE[(length(squaredErrors_OLRE)+1):(length(squaredErrors_OLRE)+3)] = (exp(predicted3)-testing_set[['entries']])^2
}

# calculate the MSE
mean(squaredErrors_nbinom1)
mean(squaredErrors_nbinom2)
mean(squaredErrors_OLRE)
# RESULT: the nbinom1 model has the lowest MSE and will be used to test hypotheses 1-3

mX = (glmmTMB(entries ~ manipulation*group + (1|subID), data=main1, family = "nbinom1"))
mX_notInt = (glmmTMB(entries ~ manipulation+group + (1|subID), data=main1, family = "nbinom1"))
summary(mX)
anova(mX,mX_notInt) # testing the interaction effect
Anova(mX,type=3) # If wanting to check the estimated main effects. (see this: https://stats.stackexchange.com/questions/60362/choice-between-type-i-type-ii-or-type-iii-anova and https://stats.stackexchange.com/questions/20452/how-to-interpret-type-i-type-ii-and-type-iii-anova-and-manova)

# --------- create table 1: main regression (NB1) analysis
theme_set(theme_sjplot())
tab_model(mX, transform = NULL, show.se=TRUE, show.ci = FALSE,wrap.labels = 100,
          dv.labels = 'Entries', pred.labels=c('(Intercept)','Manipulation [Devaluation]','Manipulation [Control - post]',
                                                'Group [Extensive Training]','Group [Extensive Training - Parallel week1 manipulations]',
                                                'Manipulation [Devaluation] * Group [Extensive Training]','Manipulation [Control - post] * Group [Extensive Training]',
                                                'Manipulation [Devaluation] * Group [Extensive Training - Parallel week1 manipulations]','Manipulation [Control - post] * Group [Extensive Training - Parallel week1 manipulations]'),
          show.r2=FALSE, show.icc=FALSE, show.zeroinf=FALSE, show.ngroups=FALSE,
          show.obs = FALSE, show.re.var=FALSE, title='Table 1', file='/Users/ranigera/Downloads/Tab1.html')
webshot("/Users/ranigera/Downloads/Tab1.html", "/Users/ranigera/Downloads/Tab1.png")

# ------- Running the model with other baselines to test others simple effects:
# compare simple interactions of the main effect of interest between the two extensive trianing gorups
# and simple effect of pre vs post for the extensive training group:
main_lt_baseline = within(main1, group <- relevel(group, ref = 'long_training'))
summary(glmmTMB(entries ~ manipulation*group + (1|subID), data=main_lt_baseline, family = "nbinom1"))

# compare simple effect of pre vs post for the extensive training with parallel manipulations group:
main_ltp_baseline = within(main1, group <- relevel(group, ref = 'long_training_parallel_manipulations'))
summary(glmmTMB(entries ~ manipulation*group + (1|subID), data=main_ltp_baseline, family = "nbinom1"))

main_deval_baseline = within(main1, manipulation <- relevel(manipulation, ref = 'deval'))
summary(glmmTMB(entries ~ manipulation*group + (1|subID), data=main_deval_baseline, family = "nbinom1"))



# *******************************************************************************************************
##### Proportions Z-tested to compare porportion of participants with 0 habitual responses between groups
# *******************************************************************************************************

no_habitual_rep= c(length(main$deval[main$group=="short_training" & main$deval==0]),
                   length(main$deval[main$group=="long_training" & main$deval==0]),
                   length(main$deval[main$group=="long_training_parallel_manipulations" & main$deval==0]))

n= c(length(main$deval[main$group=="short_training"]),
     length(main$deval[main$group=="long_training"]),
     length(main$deval[main$group=="long_training_parallel_manipulations"]))

prop.test(no_habitual_rep, n)
prop.test(no_habitual_rep[c(1,2)], n[c(1,2)])#, alternative="greater")
prop.test(no_habitual_rep[c(1,3)], n[c(1,3)])#, alternative="greater")



####################################################################################################################################
##########################################            BEHAVIORAL ADAPTATION INDEX           ########################################
####################################################################################################################################

set.seed(1)
main = app_data[c('subID','group','training_length','preVal_relativeDiff_deval_SQRT','meanVal_relativeDiff_deval_SQRT')]
main$group = as.factor(main$group)
main$training_length = as.factor(main$training_length)
#main$preVal_relativeDiff_deval_SQRT = as.numeric(scale(main$preVal_relativeDiff_deval_SQRT))
#main$meanVal_relativeDiff_deval_SQRT = as.numeric(scale(main$meanVal_relativeDiff_deval_SQRT))

#main=main[main$subID!=304,]
only_short = main[main$group == 'short_training',]
only_long = main[main$group != 'short_training',]
only_long_reg = main[main$group == 'long_training',]
only_long_par = main[main$group == 'long_training_parallel_manipulations',]

# comparing extensive training group to determine if to collapse their data together:
t.test(only_long_reg$meanVal_relativeDiff_deval_SQRT, only_long_par$meanVal_relativeDiff_deval_SQRT, var.equal = TRUE)
# comparing short vs. extensive training groups (collapsed):
t.test(only_short$meanVal_relativeDiff_deval_SQRT, only_long$meanVal_relativeDiff_deval_SQRT, var.equal = TRUE)

#--------------------------- FLEXMIX TO IDENTIFY CLUSTERS -----------------
# what is the number of clusters that better explains the data in each group
n_clusters_short <- stepFlexmix(meanVal_relativeDiff_deval_SQRT~1, data = only_short, control = list(verbose = 0), k = 1:2, nrep = 200)
mixlm_short <- getModel(n_clusters_short, "BIC")
plot(n_clusters_short)
BIC(n_clusters_short)
# get cluster size
getModel(n_clusters_short, which = 1)
getModel(n_clusters_short, which = 2)

n_clusters_long <- stepFlexmix(meanVal_relativeDiff_deval_SQRT~1, data = only_long, control = list(verbose = 0), k = 1:2, nrep = 200)
mixlm_long <- getModel(n_clusters_long, "BIC") # get best clusters amount
plot(n_clusters_long)
BIC(n_clusters_long)
# get cluster size
getModel(n_clusters_long, which = 1)
getModel(n_clusters_long, which = 2)

only_short$Cluster = factor(clusters(mixlm_short)) # create a variable based on the clustering
only_long$Cluster = factor(clusters(mixlm_long)) # create a variable based on the clustering
combined_short_long=rbind(only_short, only_long)

#--------------------------- Plot clusters distribution -----------------
# rename variables for plot
combined_short_long$training_length <- dplyr::recode(combined_short_long$training_length, "short" = "Short training", "long" = "Extensive training" )
combined_short_long$Cluster   <- dplyr::recode(combined_short_long$Cluster, "1" = "Goal-directed", "2" = "Habitual" )
combined_short_long$training_length = factor(combined_short_long$training_length, levels=c('Short training','Extensive training'))

dat_text <- data.frame(label = factor(c("Short training", "Extensive training"),levels=c("Short training", "Extensive training")),
                       training_length = factor(c("Short training", "Extensive training"),levels=c("Short training", "Extensive training")),
                       x= c(1, 1),  y = c(1.7, 1.7))

p <-  ggplot(combined_short_long, aes(meanVal_relativeDiff_deval_SQRT, fill = Cluster)) +
  #geom_histogram(aes(y=..density..),alpha=0.2,binwidth=0.3)+
  geom_density(alpha = 0.5)+
  xlab('Behavioral adaptation index')+
  ylab('Density')+
  facet_wrap(training_length~.,ncol=1)+
  geom_text(data=dat_text, mapping = aes(x=x, y=y, label=label), inherit.aes=FALSE,vjust = "inward", hjust = c(1.6,1.35), check_overlap = TRUE, size=5.1 , fontface = "bold") +
  scale_fill_manual(values=c("turquoise4", "coral3")) +
  scale_x_continuous(breaks = seq(-10, 10, by = 0.2)) +
  theme_bw()

pp <- p + theme_classic(base_size = 11, base_family = "Helvetica")+
  theme(
    strip.background = element_blank(),
    strip.text = element_blank(),
    panel.grid.minor = element_blank(),
    axis.title.x = element_text(size = 16),
    axis.title.y = element_text(size = 16),
    panel.grid.major = element_line(color="gray", size=0.1),
    legend.position = c(0.22, 0.84),
    legend.background = element_rect(fill = "white", color = "gray"),
    aspect.ratio=0.8
  )

pp$labels$fill <- "Subgroup"
pp
ggsave(file.path(figures_path,'Cluster_analysis.tiff'), pp, dpi = 100, height = 605, width=416, units = "px")



####################################################################################################################################
##########################################            ENGAGEMENT PATTERNS RELATED ANALYSIS           ###############################
####################################################################################################################################

# *******************************************************************************
##### Baseline engagement rates - upper and lower quartile (1st vs. 4th quartile)
# *******************************************************************************

main = app_data[c('subID','still_valued','devaluation','still_valued_post_deval','mean_still_valued','meanVal_relativeDiff_deval','meanVal_relativeDiff_deval_SQRT','group','training_length')]
main$group = as.factor(main$group)
main$training_length = as.factor(main$training_length)
main = within(main, group <- relevel(group, ref = 'short_training'))
main = within(main, training_length <- relevel(training_length, ref = 'short'))

short = main[main$training_length=='short',]
long = main[main$training_length=='long',]

short[short$still_valued <= quantile(short$still_valued,0.25),'qrtle'] = 'Q1'
short[short$still_valued >= quantile(short$still_valued,0.75),'qrtle'] = 'Q4'
short = short[!is.na(short$qrtle),]
long[long$still_valued <= quantile(long$still_valued,0.25),'qrtle'] = 'Q1'
long[long$still_valued >= quantile(long$still_valued,0.75),'qrtle'] = 'Q4'
long = long[!is.na(long$qrtle),]

quartileData = rbind(short,long)
quartileData$qrtle = as.factor(quartileData$qrtle)
quartileData = within(quartileData, qrtle <- relevel(qrtle, ref = 'Q1'))

summary(rf1<-rfit(meanVal_relativeDiff_deval_SQRT ~ training_length*qrtle, data=quartileData))
summary(rf2<-rfit(meanVal_relativeDiff_deval_SQRT ~ training_length+qrtle, data=quartileData))
raov(rf1, data=quartileData)
drop.test(rf1,rf2)

# --------- Plot:
quartileData$training_length   <- dplyr::recode(quartileData$training_length, "short" = "Short training", "long" = "Extensive training\n(combined groups)")
quartileData$qrtle   <- dplyr::recode(quartileData$qrtle, "Q1" = "Lower quartile", "Q4" = "Upper quartile")

p <- ggplot(quartileData, aes(x = qrtle, y = meanVal_relativeDiff_deval_SQRT, fill=qrtle, color = qrtle)) +
  geom_point(alpha = .2, position = position_jitterdodge(jitter.width = .5, jitter.height = 0)) +
  geom_boxplot(alpha=0.3,outlier.alpha =0) +
  scale_y_continuous(breaks= pretty_breaks()) +
  ylab('Behavioral adaptation index')+
  xlab('Baseline entries') +
  facet_grid(.~training_length) +
  scale_x_discrete(drop = FALSE, labels=c("gold_mean_val" = "Valued", "gold_deval" = "Devalued")) +
  scale_fill_manual(values=c("slateblue", "darkorange3")) + scale_color_manual(values=c("slateblue", "darkorange3"))


pp <- p + theme_light(base_size = 18, base_family = "Helvetica")+
  theme(strip.text.x = element_text(size = 20, face = "bold"),
        strip.text.y = element_text(size = 20, face = "bold"),
        strip.text = element_text(colour = 'black'),
        strip.background = element_rect(color="white", fill="white", linetype="solid"),
        axis.text.x = element_text(face="bold", size=14),
        axis.text.y = element_text(face="bold", size=14),
        axis.ticks.x = element_blank(),
        #legend.box.background = element_blank(),
        legend.position="none",
        panel.grid.minor = element_blank(),
        panel.grid.major = element_line(color="gray", size=0.05),
        axis.title.x = element_text(size = 18, face = "bold"),
        axis.title.y = element_text(size = 18, face = "bold"))

pp

ggsave(file.path(figures_path,'baseline_quartiles.tiff'), pp, dpi = 100)



# *******************************************************************************
##### Effects of sessions  entries (avg. #sessions and avg. #entries per session)
# *******************************************************************************

main = app_data[c('subID','timeDelta_n_sessionsPerDay', 'timeDelta_avgSessionEntries','still_valued','devaluation','still_valued_post_deval','mean_still_valued','meanVal_relativeDiff_deval','meanVal_relativeDiff_deval_SQRT','group','training_length')]

main$training_length[main$training_length=='short'] = -1
main$training_length[main$training_length=='long'] = 1
main$training_length = as.numeric(main$training_length)
scaled_meanVal_relativeDiff_deval_SQRT = scale(main$meanVal_relativeDiff_deval_SQRT)
main$meanVal_relativeDiff_deval_SQRT = as.numeric(scaled_meanVal_relativeDiff_deval_SQRT)
scaled_timeDelta_n_sessionsPerDay = scale(main$timeDelta_n_sessionsPerDay)
main$timeDelta_n_sessionsPerDay = as.numeric(scaled_timeDelta_n_sessionsPerDay)
scaled_timeDelta_avgSessionEntries = scale(main$timeDelta_avgSessionEntries)
main$timeDelta_avgSessionEntries = as.numeric(scaled_timeDelta_avgSessionEntries)

# rfit does Rank-based estimates for linear models https://rdrr.io/cran/Rfit/man/rfit.html
summary(rf1 <- rfit(meanVal_relativeDiff_deval_SQRT ~ timeDelta_n_sessionsPerDay*timeDelta_avgSessionEntries*training_length ,data = main))
# testing the interaction effect
summary(rf1_no_3way_inter <- rfit(meanVal_relativeDiff_deval_SQRT ~ timeDelta_avgSessionEntries*training_length +
                                    timeDelta_n_sessionsPerDay*timeDelta_avgSessionEntries + 
                                    timeDelta_n_sessionsPerDay*training_length ,data = main))
drop.test(rf1,rf1_no_3way_inter)

# testing 2-way interaction effects
summary(rf1_no_n_sessionsPerDay_x_group_int <- rfit(meanVal_relativeDiff_deval_SQRT ~ timeDelta_avgSessionEntries*training_length +
                                                            timeDelta_n_sessionsPerDay*timeDelta_avgSessionEntries + 
                                                            timeDelta_n_sessionsPerDay:timeDelta_avgSessionEntries:training_length
                                                          ,data = main))
drop.test(rf1,rf1_no_n_sessionsPerDay_x_group_int)

summary(rf1_no_avgSessionEntries_x_group_int <- rfit(meanVal_relativeDiff_deval_SQRT ~ timeDelta_n_sessionsPerDay*training_length +
                                                            timeDelta_n_sessionsPerDay*timeDelta_avgSessionEntries + 
                                                            timeDelta_n_sessionsPerDay:timeDelta_avgSessionEntries:training_length
                                                          ,data = main))
drop.test(rf1,rf1_no_avgSessionEntries_x_group_int)

summary(rf1_no_n_sessionsPerDay_x_avgSessionEntries <- rfit(meanVal_relativeDiff_deval_SQRT ~ timeDelta_n_sessionsPerDay*training_length +
                                                              training_length*timeDelta_avgSessionEntries + 
                                                              timeDelta_n_sessionsPerDay:timeDelta_avgSessionEntries:training_length
                                                            ,data = main))
drop.test(rf1,rf1_no_n_sessionsPerDay_x_avgSessionEntries)

# testing main effects
summary(rf1_main_n_sessionsPerDay <- rfit(meanVal_relativeDiff_deval_SQRT ~ timeDelta_avgSessionEntries*training_length + timeDelta_n_sessionsPerDay:timeDelta_avgSessionEntries + 
                                            timeDelta_n_sessionsPerDay:training_length + timeDelta_n_sessionsPerDay:timeDelta_avgSessionEntries:training_length ,data = main))
summary(rf1_main_avgSessionEntries <- rfit(meanVal_relativeDiff_deval_SQRT ~ timeDelta_n_sessionsPerDay*training_length + timeDelta_n_sessionsPerDay:timeDelta_avgSessionEntries + 
                                             timeDelta_avgSessionEntries:training_length + timeDelta_n_sessionsPerDay:timeDelta_avgSessionEntries:training_length ,data = main))
summary(rf1_main_training_duration <- rfit(meanVal_relativeDiff_deval_SQRT ~ timeDelta_avgSessionEntries*timeDelta_n_sessionsPerDay + training_length:timeDelta_avgSessionEntries + 
                                             timeDelta_n_sessionsPerDay:training_length + timeDelta_n_sessionsPerDay:timeDelta_avgSessionEntries:training_length ,data = main))
drop.test(rf1,rf1_main_n_sessionsPerDay) # main effect
drop.test(rf1,rf1_main_avgSessionEntries) # main effect
drop.test(rf1,rf1_main_training_duration) # no effect

# --------- Plot:
SDforPlotingSessionIndices = 3
avgEntriesSeq <- seq(min(main$timeDelta_avgSessionEntries), SDforPlotingSessionIndices, by = .02)
avgSessSeq <- seq(min(main$timeDelta_n_sessionsPerDay), SDforPlotingSessionIndices, by = .02)
grSeq <- seq(min(main$training_length), max(main$training_length), by = 2)
habitIndGrid <- expand.grid(timeDelta_avgSessionEntries = avgEntriesSeq, timeDelta_n_sessionsPerDay = avgSessSeq, training_length=grSeq)

habitIndFit = rf1$betahat[1]+
  rf1$betahat[2]*habitIndGrid[,'timeDelta_n_sessionsPerDay']+
  rf1$betahat[3]*habitIndGrid[,'timeDelta_avgSessionEntries']+
  rf1$betahat[4]*habitIndGrid[,'training_length']+
  rf1$betahat[5]*habitIndGrid[,'timeDelta_n_sessionsPerDay']*habitIndGrid[,'timeDelta_avgSessionEntries']+
  rf1$betahat[6]*habitIndGrid[,'timeDelta_n_sessionsPerDay']*habitIndGrid[,'training_length']+
  rf1$betahat[7]*habitIndGrid[,'timeDelta_avgSessionEntries']*habitIndGrid[,'training_length']+
  rf1$betahat[8]*habitIndGrid[,'timeDelta_n_sessionsPerDay']*habitIndGrid[,'timeDelta_avgSessionEntries']*habitIndGrid[,'training_length']

# setting values larger than the maximum ("utter goal-directedness") to the maximum 
habitIndFit[habitIndFit>max(main$meanVal_relativeDiff_deval_SQRT)] = max(main$meanVal_relativeDiff_deval_SQRT)

# change names for plotting
habitIndGrid$training_length <- dplyr::recode(habitIndGrid$training_length, "1" = "Extensive training\n(combined groups)","-1" = "Short training")
habitIndGrid$training_length = factor(habitIndGrid$training_length, levels=c('Short training','Extensive training\n(combined groups)'))
main_plot = main
main_plot = main_plot[main_plot$timeDelta_n_sessionsPerDay<SDforPlotingSessionIndices & main_plot$timeDelta_avgSessionEntries<SDforPlotingSessionIndices,]
colnames(main_plot)[9] = 'fit'
main_plot$training_length <- dplyr::recode(main_plot$training_length, "1" = "Extensive training\n(combined groups)","-1" = "Short training")
main_plot$training_length = factor(main_plot$training_length, levels=c('Short training','Extensive training\n(combined groups)'))

# use the scaled variables to get back to the original measures for plotting:
main_plot$fit = main_plot$fit * attr(scaled_meanVal_relativeDiff_deval_SQRT,'scaled:scale') + attr(scaled_meanVal_relativeDiff_deval_SQRT,'scaled:center')
main_plot$timeDelta_n_sessionsPerDay = main_plot$timeDelta_n_sessionsPerDay * attr(scaled_timeDelta_n_sessionsPerDay,'scaled:scale') + attr(scaled_timeDelta_n_sessionsPerDay,'scaled:center')
main_plot$timeDelta_avgSessionEntries = main_plot$timeDelta_avgSessionEntries * attr(scaled_timeDelta_avgSessionEntries,'scaled:scale') + attr(scaled_timeDelta_avgSessionEntries,'scaled:center')
habitIndFit = habitIndFit * attr(scaled_meanVal_relativeDiff_deval_SQRT,'scaled:scale') + attr(scaled_meanVal_relativeDiff_deval_SQRT,'scaled:center')
habitIndGrid$timeDelta_n_sessionsPerDay = habitIndGrid$timeDelta_n_sessionsPerDay * attr(scaled_timeDelta_n_sessionsPerDay,'scaled:scale') + attr(scaled_timeDelta_n_sessionsPerDay,'scaled:center')
habitIndGrid$timeDelta_avgSessionEntries = habitIndGrid$timeDelta_avgSessionEntries * attr(scaled_timeDelta_avgSessionEntries,'scaled:scale') + attr(scaled_timeDelta_avgSessionEntries,'scaled:center')


p <- ggplot(mutate(habitIndGrid, fit = as.numeric(habitIndFit)),
  aes(x = timeDelta_avgSessionEntries, y = timeDelta_n_sessionsPerDay, z = fit)) +
  geom_tile(aes(fill = fit)) + geom_contour() + scale_fill_gradient2(guide = guide_colourbar(title.position = "top",title = "Behavioral\nadaptation\nindex", title.hjust = 0.5)) +
  geom_point(aes(fill=fit),main_plot, alpha = 1,shape = 21, colour = "black",size=2) +
  #coord_fixed() +
  facet_grid(~training_length) +
  scale_x_continuous(breaks = breaks_extended(6)) +
  xlab('Average # entries per session')+
  ylab('Average # sessions per day')
  

pp <- p + theme_minimal(base_size = 14, base_family = "Helvetica")+
  theme(strip.text.x = element_text(size = 16, face = "bold"),
        strip.text.y = element_text(size = 16, face = "bold"),
        strip.text = element_text(colour = 'black'),
        strip.background = element_rect(color="white", fill="white", linetype="solid"),
        axis.text.x = element_text(face="bold", size=12),
        axis.ticks.x = element_blank(),
        #legend.box.background = element_blank(),
        panel.grid.minor = element_blank(),
        panel.grid.major = element_line(color="gray", size=0.05),
        axis.title.x = element_text(size = 14, face = "bold"),
        axis.title.y = element_text(size = 14, face = "bold"),
        legend.key.height = unit(1, "cm"),
        legend.spacing.y = unit(.5, 'cm'),
        aspect.ratio=0.8) 

pp
ggsave(file.path(figures_path,'Session_indices_contour_map.tiff'), pp, dpi = 100)


## Return on the same analysis after omitting all manipulations days for the session indices:
##-------------------------------------------------------------------------------------------

main = app_data[c('subID','timeDelta_n_sessionsPerDay_no_manipulations', 'timeDelta_avgSessionEntries_no_manipulations','still_valued','devaluation','still_valued_post_deval','mean_still_valued','meanVal_relativeDiff_deval','meanVal_relativeDiff_deval_SQRT','group','training_length')]
colnames(main)[2] = 'timeDelta_n_sessionsPerDay'
colnames(main)[3] = 'timeDelta_avgSessionEntries'
main$training_length[main$training_length=='short'] = -1
main$training_length[main$training_length=='long'] = 1
main$training_length = as.numeric(main$training_length)
main$meanVal_relativeDiff_deval_SQRT = as.numeric(scale(main$meanVal_relativeDiff_deval_SQRT))
main$timeDelta_n_sessionsPerDay = as.numeric(scale(main$timeDelta_n_sessionsPerDay))
main$timeDelta_avgSessionEntries = as.numeric(scale(main$timeDelta_avgSessionEntries))


# rfit does Rank-based estimates for linear models https://rdrr.io/cran/Rfit/man/rfit.html
summary(rf1 <- rfit(meanVal_relativeDiff_deval_SQRT ~ timeDelta_n_sessionsPerDay*timeDelta_avgSessionEntries*training_length ,data = main))
# testing the interaction effect
summary(rf1_no_3way_inter <- rfit(meanVal_relativeDiff_deval_SQRT ~ timeDelta_avgSessionEntries*training_length +
                                    timeDelta_n_sessionsPerDay*timeDelta_avgSessionEntries + 
                                    timeDelta_n_sessionsPerDay*training_length ,data = main))
drop.test(rf1,rf1_no_3way_inter)

# testing 2-way interaction effects
summary(rf1_no_n_sessionsPerDay_x_group_int <- rfit(meanVal_relativeDiff_deval_SQRT ~ timeDelta_avgSessionEntries*training_length +
                                                      timeDelta_n_sessionsPerDay*timeDelta_avgSessionEntries + 
                                                      timeDelta_n_sessionsPerDay:timeDelta_avgSessionEntries:training_length
                                                    ,data = main))
drop.test(rf1,rf1_no_n_sessionsPerDay_x_group_int)

summary(rf1_no_avgSessionEntries_x_group_int <- rfit(meanVal_relativeDiff_deval_SQRT ~ timeDelta_n_sessionsPerDay*training_length +
                                                       timeDelta_n_sessionsPerDay*timeDelta_avgSessionEntries + 
                                                       timeDelta_n_sessionsPerDay:timeDelta_avgSessionEntries:training_length
                                                     ,data = main))
drop.test(rf1,rf1_no_avgSessionEntries_x_group_int)

summary(rf1_no_n_sessionsPerDay_x_avgSessionEntries <- rfit(meanVal_relativeDiff_deval_SQRT ~ timeDelta_n_sessionsPerDay*training_length +
                                                              training_length*timeDelta_avgSessionEntries + 
                                                              timeDelta_n_sessionsPerDay:timeDelta_avgSessionEntries:training_length
                                                            ,data = main))
drop.test(rf1,rf1_no_n_sessionsPerDay_x_avgSessionEntries)

# testing main effects
summary(rf1_main_n_sessionsPerDay <- rfit(meanVal_relativeDiff_deval_SQRT ~ timeDelta_avgSessionEntries*training_length + timeDelta_n_sessionsPerDay:timeDelta_avgSessionEntries + 
                                            timeDelta_n_sessionsPerDay:training_length + timeDelta_n_sessionsPerDay:timeDelta_avgSessionEntries:training_length ,data = main))
summary(rf1_main_avgSessionEntries <- rfit(meanVal_relativeDiff_deval_SQRT ~ timeDelta_n_sessionsPerDay*training_length + timeDelta_n_sessionsPerDay:timeDelta_avgSessionEntries + 
                                             timeDelta_avgSessionEntries:training_length + timeDelta_n_sessionsPerDay:timeDelta_avgSessionEntries:training_length ,data = main))
summary(rf1_main_training_duration <- rfit(meanVal_relativeDiff_deval_SQRT ~ timeDelta_avgSessionEntries*timeDelta_n_sessionsPerDay + training_length:timeDelta_avgSessionEntries + 
                                             timeDelta_n_sessionsPerDay:training_length + timeDelta_n_sessionsPerDay:timeDelta_avgSessionEntries:training_length ,data = main))
drop.test(rf1,rf1_main_n_sessionsPerDay) # main effect
drop.test(rf1,rf1_main_avgSessionEntries) # main effect
drop.test(rf1,rf1_main_training_duration) # no effect

# --------- Plot:
SDforPlotingSessionIndices = 3
avgEntriesSeq <- seq(min(main$timeDelta_avgSessionEntries), SDforPlotingSessionIndices, by = .05)
avgSessSeq <- seq(min(main$timeDelta_n_sessionsPerDay), SDforPlotingSessionIndices, by = .05)
grSeq <- seq(min(main$training_length), max(main$training_length), by = 2)
habitIndGrid <- expand.grid(timeDelta_avgSessionEntries = avgEntriesSeq, timeDelta_n_sessionsPerDay = avgSessSeq, training_length=grSeq)

habitIndFit = rf1$betahat[1]+
  rf1$betahat[2]*habitIndGrid[,'timeDelta_n_sessionsPerDay']+
  rf1$betahat[3]*habitIndGrid[,'timeDelta_avgSessionEntries']+
  rf1$betahat[4]*habitIndGrid[,'training_length']+
  rf1$betahat[5]*habitIndGrid[,'timeDelta_n_sessionsPerDay']*habitIndGrid[,'timeDelta_avgSessionEntries']+
  rf1$betahat[6]*habitIndGrid[,'timeDelta_n_sessionsPerDay']*habitIndGrid[,'training_length']+
  rf1$betahat[7]*habitIndGrid[,'timeDelta_avgSessionEntries']*habitIndGrid[,'training_length']+
  rf1$betahat[8]*habitIndGrid[,'timeDelta_n_sessionsPerDay']*habitIndGrid[,'timeDelta_avgSessionEntries']*habitIndGrid[,'training_length']

# setting values larger than the maximum ("utter goal-directedness") to the maximum 
habitIndFit[habitIndFit>max(main$meanVal_relativeDiff_deval_SQRT)] = max(main$meanVal_relativeDiff_deval_SQRT)

# change names for plotting
habitIndGrid$training_length <- dplyr::recode(habitIndGrid$training_length, "-1" = "Extensive training\n(combined groups)","1" = "Short training")
habitIndGrid$training_length = factor(habitIndGrid$training_length, levels=c('Short training','Extensive training\n(combined groups)'))
main_plot = main
main_plot = main_plot[main_plot$timeDelta_n_sessionsPerDay<SDforPlotingSessionIndices & main_plot$timeDelta_avgSessionEntries<SDforPlotingSessionIndices,]
colnames(main_plot)[9] = 'fit'
main_plot$training_length <- dplyr::recode(main_plot$training_length, "-1" = "Extensive training\n(combined groups)","1" = "Short training")
main_plot$training_length = factor(main_plot$training_length, levels=c('Short training','Extensive training\n(combined groups)'))

# use the scaled variables to get back to the original measures for plotting:
main_plot$fit = main_plot$fit * attr(scaled_meanVal_relativeDiff_deval_SQRT,'scaled:scale') + attr(scaled_meanVal_relativeDiff_deval_SQRT,'scaled:center')
main_plot$timeDelta_n_sessionsPerDay = main_plot$timeDelta_n_sessionsPerDay * attr(scaled_timeDelta_n_sessionsPerDay,'scaled:scale') + attr(scaled_timeDelta_n_sessionsPerDay,'scaled:center')
main_plot$timeDelta_avgSessionEntries = main_plot$timeDelta_avgSessionEntries * attr(scaled_timeDelta_avgSessionEntries,'scaled:scale') + attr(scaled_timeDelta_avgSessionEntries,'scaled:center')
habitIndFit = habitIndFit * attr(scaled_meanVal_relativeDiff_deval_SQRT,'scaled:scale') + attr(scaled_meanVal_relativeDiff_deval_SQRT,'scaled:center')
habitIndGrid$timeDelta_n_sessionsPerDay = habitIndGrid$timeDelta_n_sessionsPerDay * attr(scaled_timeDelta_n_sessionsPerDay,'scaled:scale') + attr(scaled_timeDelta_n_sessionsPerDay,'scaled:center')
habitIndGrid$timeDelta_avgSessionEntries = habitIndGrid$timeDelta_avgSessionEntries * attr(scaled_timeDelta_avgSessionEntries,'scaled:scale') + attr(scaled_timeDelta_avgSessionEntries,'scaled:center')

p <- ggplot(mutate(habitIndGrid, fit = as.numeric(habitIndFit)),
            aes(x = timeDelta_avgSessionEntries, y = timeDelta_n_sessionsPerDay, z = fit)) +
  geom_tile(aes(fill = fit)) + geom_contour(binwidth = 0.05) + scale_fill_gradient2(guide = guide_colourbar(title.position = "top",title = "Behavioral\nadaptation\nindex", title.hjust = 0.5)) +
  geom_point(aes(fill=fit),main_plot, alpha = 1,shape = 21, colour = "black",size=2) +
  #coord_fixed() +
  facet_grid(~training_length) +
  scale_x_continuous(breaks = breaks_extended(6)) +
  ylab('Average # sessions per day')+
  xlab('Average # entries per session')

pp <- p + theme_minimal(base_size = 14, base_family = "Helvetica")+
  theme(strip.text.x = element_text(size = 16, face = "bold"),
        strip.text.y = element_text(size = 16, face = "bold"),
        strip.text = element_text(colour = 'black'),
        strip.background = element_rect(color="white", fill="white", linetype="solid"),
        axis.text.x = element_text(face="bold", size=12),
        axis.ticks.x = element_blank(),
        #legend.box.background = element_blank(),
        panel.grid.minor = element_blank(),
        panel.grid.major = element_line(color="gray", size=0.05),
        axis.title.x = element_text(size = 14, face = "bold"),
        axis.title.y = element_text(size = 14, face = "bold"),
        legend.key.height = unit(1, "cm"),
        legend.spacing.y = unit(.5, 'cm'),
        aspect.ratio=0.8) 

pp
ggsave(file.path(figures_path,'Session_indices_contour_map2.tiff'), pp, dpi = 100)



# *******************************************************************************
##### Engagement based on the first day entries and on total number of entries
# *******************************************************************************

# assemble the relevant data:
# separate groups (for some analyses)
short = subset(app_data, training_length=="short")
long = subset(app_data, training_length=="long")
# separate groups (for some analyses)
short_training = subset(app_data, group=="short_training")
long_training = subset(app_data, group=="long_training")
long_training_par = subset(app_data, group=="long_training_parallel_manipulations")

# assemble data for (exploratory) rank-based regression analyses:
ind_diff_data = app_data
firstDayEntries_scaled = scale(ind_diff_data$firstDayEntries)
ind_diff_data$firstDayEntries = firstDayEntries_scaled[,1]
# get averaged daily entries
ind_diff_data[ind_diff_data$training_length=='short', 'avgDailyEntries'] = ind_diff_data$allEntries[ind_diff_data$training_length=='short']/3
ind_diff_data[ind_diff_data$training_length=='long', 'avgDailyEntries'] = ind_diff_data$allEntries[ind_diff_data$training_length=='long']/10
avgDailyEntries_scaled = scale(ind_diff_data$avgDailyEntries)
ind_diff_data$avgDailyEntries = avgDailyEntries_scaled[,1]
allEntries_scaled = scale(ind_diff_data$allEntries)
ind_diff_data$allEntries = allEntries_scaled[,1]
ind_diff_data$allEntriesAcrossNoManipulationDay = scale(ind_diff_data$allEntriesAcrossNoManipulationDay)[,1]
ind_diff_data$timeDelta_avgSessionEntries = scale(ind_diff_data$timeDelta_avgSessionEntries)[,1]
ind_diff_data$timeDelta_n_sessionsPerDay = scale(ind_diff_data$timeDelta_n_sessionsPerDay)[,1]
ind_diff_data$NormedVar_entriesAcrossNoDevalDays = scale(ind_diff_data$NormedVar_entriesAcrossNoDevalDays)[,1]
meanVal_relativeDiff_deval_SQRT_scaled = scale(ind_diff_data$meanVal_relativeDiff_deval_SQRT)
ind_diff_data$meanVal_relativeDiff_deval_SQRT = meanVal_relativeDiff_deval_SQRT_scaled[,1]
ind_diff_data$training_length[ind_diff_data$training_length=='short'] = -1
ind_diff_data$training_length[ind_diff_data$training_length=='long'] = 1
ind_diff_data$training_length = as.numeric(ind_diff_data$training_length)

short[,'avgDailyEntries'] = short$allEntries/3
long[,'avgDailyEntries'] = long$allEntries/10

## By the first day:
# ----------------------------------------------------
cor.test(long$firstDayEntries, long$meanVal_relativeDiff_deval_SQRT, method='spearman', alternative="greater")
# exploratory (short training):
cor.test(short$firstDayEntries, short$meanVal_relativeDiff_deval_SQRT, method='spearman', alternative="greater") 

# rank-based regression:
summary(rm1 <- rfit(meanVal_relativeDiff_deval_SQRT ~ firstDayEntries*training_length ,data = ind_diff_data))
summary(no_int <- rfit(meanVal_relativeDiff_deval_SQRT ~ firstDayEntries+training_length ,data = ind_diff_data))
drop.test(rm1,no_int)
summary(no_group <- rfit(meanVal_relativeDiff_deval_SQRT ~ firstDayEntries + firstDayEntries:training_length ,data = ind_diff_data))
summary(no_firstDayEntries <- rfit(meanVal_relativeDiff_deval_SQRT ~ training_length + firstDayEntries:training_length ,data = ind_diff_data))
drop.test(rm1,no_group)
drop.test(rm1,no_firstDayEntries)

# --------- Plot:
ind_diff_data_plot = app_data # get the data unscaled
# create fit for the short training:
grid_firstDayEntries_Short = seq(min(ind_diff_data$firstDayEntries), max(ind_diff_data$firstDayEntries), by = .01)
fitShort = rm1$betahat[1]+
  rm1$betahat[2]*grid_firstDayEntries_Short+
  rm1$betahat[3]*-1+ #-1 as this is how the short training was coded.
  rm1$betahat[4]*grid_firstDayEntries_Short*-1 #-1 as this is how the short training was coded.
# use the scaled variables to get back to the original measures for plotting:
fit = fitShort * attr(meanVal_relativeDiff_deval_SQRT_scaled,'scaled:scale') + attr(meanVal_relativeDiff_deval_SQRT_scaled,'scaled:center')
grid_firstDayEntries = grid_firstDayEntries_Short * attr(firstDayEntries_scaled,'scaled:scale') + attr(firstDayEntries_scaled,'scaled:center')
line_dat = data.frame(grid_firstDayEntries,fit)
line_dat['training_length']=-1

# create fit for the extensive training:
grid_firstDayEntries_Long = seq(min(ind_diff_data$firstDayEntries), max(ind_diff_data$firstDayEntries), by = .01)
fitLong = rm1$betahat[1]+
  rm1$betahat[2]*grid_firstDayEntries_Long+
  rm1$betahat[3]*1+ #1 as this is how the LONG training was coded.
  rm1$betahat[4]*grid_firstDayEntries_Long*1 #1 as this is how the LONG training was coded.
# use the scaled variables to get back to the original measures for plotting:
fit = fitLong * attr(meanVal_relativeDiff_deval_SQRT_scaled,'scaled:scale') + attr(meanVal_relativeDiff_deval_SQRT_scaled,'scaled:center')
grid_firstDayEntries = grid_firstDayEntries_Long * attr(firstDayEntries_scaled,'scaled:scale') + attr(firstDayEntries_scaled,'scaled:center')
line_dat2 = data.frame(grid_firstDayEntries,fit)
line_dat2['training_length']=1

#combine:
lines_DATA = rbind(line_dat, line_dat2)

#rename variables:
ind_diff_data_plot$training_length <- dplyr::recode(ind_diff_data_plot$training_length, "short" = "Short","long" = "Extensive")
lines_DATA$training_length <- dplyr::recode(lines_DATA$training_length, "-1" = "Short","1" = "Extensive")
ind_diff_data_plot$training_length = factor(ind_diff_data_plot$training_length, levels=c('Short','Extensive'))
lines_DATA$training_length = factor(lines_DATA$training_length, levels=c('Short','Extensive'))

ind_diff_data_plot_FirstDay = ind_diff_data_plot # to plot it together with whole days data later
lines_DATA_FirstDay = lines_DATA # to plot it together with whole days data later
p <- ggplot(ind_diff_data_plot, aes(x=firstDayEntries, y=meanVal_relativeDiff_deval_SQRT,color=training_length)) +
  geom_point()+
  geom_line(aes(grid_firstDayEntries, fit, colour=training_length), lines_DATA)+
  scale_x_continuous(breaks = breaks_extended(6)) +
  scale_y_continuous(breaks = breaks_extended(6), limits = c(-0.3, 1.02)) +
  ylab('Behavioral adaptation index')+
  xlab('# First day entries')

pp <- p + theme_classic(base_size = 14, base_family = "Helvetica")+
  theme(strip.text.x = element_text(size = 16, face = "bold"),
        strip.text.y = element_text(size = 16, face = "bold"),
        strip.text = element_text(colour = 'black'),
        strip.background = element_rect(color="white", fill="white", linetype="solid"),
        axis.text.x = element_text(face="bold", size=12),
        axis.ticks.x = element_blank(),
        #legend.box.background = element_blank(),
        panel.grid.minor = element_blank(),
        panel.grid.major = element_line(color="gray", size=0.05),
        axis.title.x = element_text(size = 14, face = "bold"),
        axis.title.y = element_text(size = 14, face = "bold"),
        legend.position = "none",
        legend.background = element_rect(fill = "white", color = "gray")) 

pp$labels$colour <- "Training duration"
pp <- ggMarginal(pp, groupColour = TRUE, groupFill = TRUE,margins = 'x')
pp
firstDays_pp = pp
ggsave(file.path(figures_path,'First_day_entries_scatter.tiff'), pp, dpi = 100)

## By All days entries (except devaluation days):
# ----------------------------------------------------
cor.test(long$avgDailyEntries, long$meanVal_relativeDiff_deval_SQRT, method='spearman', alternative="greater")
# exploratory (short training):
cor.test(short$avgDailyEntries, short$meanVal_relativeDiff_deval_SQRT, method='spearman', alternative="greater") 

# rank-based regression:
summary(rm1 <- rfit(meanVal_relativeDiff_deval_SQRT ~ avgDailyEntries*training_length ,data = ind_diff_data))
summary(no_int <- rfit(meanVal_relativeDiff_deval_SQRT ~ avgDailyEntries+training_length ,data = ind_diff_data))
drop.test(rm1,no_int)
summary(no_group <- rfit(meanVal_relativeDiff_deval_SQRT ~ avgDailyEntries + avgDailyEntries:training_length ,data = ind_diff_data))
summary(no_firstDayEntries <- rfit(meanVal_relativeDiff_deval_SQRT ~ training_length + avgDailyEntries:training_length ,data = ind_diff_data))
drop.test(rm1,no_group)
drop.test(rm1,no_firstDayEntries)

# --------- Plot:
ind_diff_data_plot = app_data # get the data unscaled
# get averaged daily entries
ind_diff_data_plot[ind_diff_data_plot$training_length=='short', 'avgDailyEntries'] = ind_diff_data_plot$allEntries[ind_diff_data_plot$training_length=='short']/3
ind_diff_data_plot[ind_diff_data_plot$training_length=='long', 'avgDailyEntries'] = ind_diff_data_plot$allEntries[ind_diff_data_plot$training_length=='long']/10

# create fit for the short training:
grid_allDaysEntries_Short = seq(min(ind_diff_data[ind_diff_data$training_length==-1,'avgDailyEntries']),
                                max(ind_diff_data[ind_diff_data$training_length==-1,'avgDailyEntries']), by = .01)
fitShort = rm1$betahat[1]+
  rm1$betahat[2]*grid_allDaysEntries_Short+
  rm1$betahat[3]*-1+ #-1 as this is how the short training was coded.
  rm1$betahat[4]*grid_allDaysEntries_Short*-1 #-1 as this is how the short training was coded.
# use the scaled variables to get back to the original measures for plotting:
fit = fitShort * attr(meanVal_relativeDiff_deval_SQRT_scaled,'scaled:scale') + attr(meanVal_relativeDiff_deval_SQRT_scaled,'scaled:center')
grid_allDaysEntries = grid_allDaysEntries_Short * attr(avgDailyEntries_scaled,'scaled:scale') + attr(avgDailyEntries_scaled,'scaled:center')
line_dat = data.frame(grid_allDaysEntries,fit)
line_dat['training_length']=-1

# create fit for the extensive training:
grid_allDaysEntries_Long = seq(min(ind_diff_data$avgDailyEntries), max(ind_diff_data$avgDailyEntries), by = .01)
fitLong = rm1$betahat[1]+
  rm1$betahat[2]*grid_allDaysEntries_Long+
  rm1$betahat[3]*1+ #1 as this is how the LONG training was coded.
  rm1$betahat[4]*grid_allDaysEntries_Long*1 #1 as this is how the LONG training was coded.
# use the scaled variables to get back to the original measures for plotting:
fit = fitLong * attr(meanVal_relativeDiff_deval_SQRT_scaled,'scaled:scale') + attr(meanVal_relativeDiff_deval_SQRT_scaled,'scaled:center')
grid_allDaysEntries = grid_allDaysEntries_Long * attr(avgDailyEntries_scaled,'scaled:scale') + attr(avgDailyEntries_scaled,'scaled:center')
line_dat2 = data.frame(grid_allDaysEntries,fit)
line_dat2['training_length']=1

#combine:
lines_DATA = rbind(line_dat, line_dat2)

#rename variables:
ind_diff_data_plot$training_length <- dplyr::recode(ind_diff_data_plot$training_length, "short" = "Short","long" = "Extensive")
lines_DATA$training_length <- dplyr::recode(lines_DATA$training_length, "-1" = "Short","1" = "Extensive")
ind_diff_data_plot$training_length = factor(ind_diff_data_plot$training_length, levels=c('Short','Extensive'))
lines_DATA$training_length = factor(lines_DATA$training_length, levels=c('Short','Extensive'))

p <- ggplot(ind_diff_data_plot, aes(x=avgDailyEntries, y=meanVal_relativeDiff_deval_SQRT,color=training_length)) +
  geom_point()+
  geom_line(aes(grid_allDaysEntries, fit, colour=training_length), lines_DATA)+
  scale_x_continuous(breaks = breaks_extended(6)) +
  scale_y_continuous(breaks = breaks_extended(6), limits = c(-0.3, 1.02)) +
  ylab('Behavioral adaptation index')+
  xlab('Avg. # daily entries')

pp <- p + theme_classic(base_size = 14, base_family = "Helvetica")+
  theme(strip.text.x = element_text(size = 16, face = "bold"),
        strip.text.y = element_blank(),
        strip.text = element_text(colour = 'black'),
        strip.background = element_rect(color="white", fill="white", linetype="solid"),
        axis.text.x = element_text(face="bold", size=12),
        axis.ticks.x = element_blank(),
        axis.ticks.y = element_blank(),
        axis.text.y = element_blank(),
        #legend.box.background = element_blank(),
        panel.grid.minor = element_blank(),
        panel.grid.major = element_line(color="gray", size=0.05),
        axis.title.x = element_text(size = 14, face = "bold"),
        axis.title.y = element_blank(),
        legend.position = c(0.8, 0.2),
        legend.background = element_rect(fill = "white", color = "gray")) 

pp$labels$colour <- "Training duration"
pp <- ggMarginal(pp, groupColour = TRUE, groupFill = TRUE)
pp
ggsave(file.path(figures_path,'All_days_entries_scatter.tiff'), pp, dpi = 100)

# Save both plots (of first day and of all days)together
x=ggarrange(firstDays_pp,pp)
ggsave(file.path(figures_path,'firstDay_and_AllEntries.tiff'), x, dpi = 100, width = 12.75, height = 6)

# The following appears in the pre-registration but is redundant given the comprehensive analysis of the effects of all session indices (done above):
# ----------------------------------------------------
## By avgSessionEntries per day:
# ----------------------------------------------------
#rcorr(long$timeDelta_avgSessionEntries, long$meanVal_relativeDiff_deval_SQRT, type='spearman')
# exploratory (short training):
#rcorr(short$timeDelta_avgSessionEntries, short$meanVal_relativeDiff_deval_SQRT, type='spearman')

# ----------------------------------------------------
## By n_sessions per day:
# ----------------------------------------------------
#rcorr(long$timeDelta_n_sessionsPerDay, long$meanVal_relativeDiff_deval_SQRT, type='spearman')
# exploratory (short training):
#rcorr(short$timeDelta_n_sessionsPerDay, short$meanVal_relativeDiff_deval_SQRT, type='spearman')


####################################################################################################################################
#########################################          DAILY VARIABILITY                ################################################
####################################################################################################################################

cor.test(long$NormedVar_entriesAcrossNoDevalDays, long$meanVal_relativeDiff_deval_SQRT, method='spearman', alternative="greater")


####################################################################################################################################
################        MODEL-BASED and MODEL-FREE learning relationships with the app habit index           #######################
####################################################################################################################################

# *******************************************************************************
##### LOGISTIC REGRESSION MAIN ANALYSIS
# *******************************************************************************

MBMF_logisticRegData = read.csv('data/MBMF/MBMF_dataForLogisticReg.csv', header=T)
app_data_temp = read.csv(habit_app_data, header=T)
# AN IMPORTANT FIX DUE TO MISTAKENLY ASSIGNING SUBJECT ID 341 IN THE APP TO 344 IN PART 3 (that includes the two-step task) 
MBMF_logisticRegData[MBMF_logisticRegData$subID == 344,]$subID = 341
# arange data
MBMF_logisticRegData = MBMF_logisticRegData[,names(MBMF_logisticRegData) != "X"] # remove an extra index column

# extract relevant subjects:
MBMF_logisticRegData = MBMF_logisticRegData[MBMF_logisticRegData$subID %in% app_data_temp$subID,]
app_data_temp = app_data_temp[app_data_temp$subID %in% unique(MBMF_logisticRegData$subID),]

# add some relevant variables to the main table
for(subId in app_data_temp$subID){
  # Add devaluation measures
  MBMF_logisticRegData[MBMF_logisticRegData$subID == subId, 'Deval'] = app_data_temp[app_data_temp$subID==subId,'meanVal_relativeDiff_deval_SQRT']
  # Add group
  MBMF_logisticRegData[MBMF_logisticRegData$subID == subId, 'group'] = app_data_temp[app_data_temp$subID==subId,'group']
}
MBMF_logisticRegData[MBMF_logisticRegData$group=='short_training','training_length'] = 'short'
MBMF_logisticRegData[MBMF_logisticRegData$group!='short_training','training_length'] = 'long'

# EXTRACT THE BETAS AND USE THE DEVALUATION SENSITIVTY AS DEPENDENT VARIABLE:
# --------------------------------------------------------------------------
# run the basic model to extract betas
summary(fit_basic <- glmer(Stay ~ Reward*Transition + (1+Reward*Transition|subID), data=MBMF_logisticRegData, family = binomial, glmerControl(optimizer="bobyqa",optCtrl=list(maxfun=100000))));
logisticReg_coefs = as.data.frame(coef(fit_basic)[[1]])
names(logisticReg_coefs) = c("intercept", "MF_ind", "trans", "MB_ind")
logisticReg_coefs$subID = rownames(logisticReg_coefs)

# add some relevant variables to the main table
for(subId in app_data_temp$subID){
  # Add devaluation measures
  logisticReg_coefs[logisticReg_coefs$subID == subId, 'Deval'] = app_data_temp[app_data_temp$subID==subId,'meanVal_relativeDiff_deval_SQRT']
  # Add group
  logisticReg_coefs[logisticReg_coefs$subID == subId, 'group'] = app_data_temp[app_data_temp$subID==subId,'group']
}
logisticReg_coefs[logisticReg_coefs$group=='short_training','training_length'] = 'short'
logisticReg_coefs[logisticReg_coefs$group!='short_training','training_length'] = 'long'

# effect coding and adjust variable types:
logisticReg_coefs$training_length[logisticReg_coefs$training_length=='short'] = -1
logisticReg_coefs$training_length[logisticReg_coefs$training_length=='long'] = 1
logisticReg_coefs$training_length = as.numeric(logisticReg_coefs$training_length)
logisticReg_coefs$Deval = as.numeric(scale(logisticReg_coefs$Deval))
logisticReg_coefs$MF_ind = as.numeric(scale(logisticReg_coefs$MF_ind))
logisticReg_coefs$MB_ind = as.numeric(scale(logisticReg_coefs$MB_ind))

# Multiple linear regression [regitered analysois]:
summary(rf1 <- lm(Deval ~ (MF_ind+MB_ind)*training_length ,data = logisticReg_coefs))
# testing the interaction effect
summary(rf1_no_group_x_MB_interactions <- lm(Deval ~ MF_ind+MB_ind+training_length+training_length:MF_ind ,data = logisticReg_coefs))
anova(rf1, rf1_no_group_x_MB_interactions)
summary(rf1_no_group_x_MF_interactions <- lm(Deval ~ MF_ind+MB_ind+training_length+training_length:MB_ind ,data = logisticReg_coefs))
anova(rf1, rf1_no_group_x_MF_interactions)
#main effects:
summary(rf1_no_group <- lm(Deval ~ MF_ind+MB_ind+training_length:MF_ind+training_length:MB_ind ,data = logisticReg_coefs))
anova(rf1, rf1_no_group)
summary(rf1_no_MB <- lm(Deval ~ MF_ind*training_length+training_length:MB_ind ,data = logisticReg_coefs))
anova(rf1, rf1_no_MB)
summary(rf1_no_MF <- lm(Deval ~ MB_ind*training_length+training_length:MF_ind ,data = logisticReg_coefs))
anova(rf1, rf1_no_MF)



# *******************************************************************************
##### COMP. MODEL BETAS analysis (registered analysis for learning rate and
##### perseverance and Exploratory for model-based and model-free parameters)
# *******************************************************************************

# set directories and load files
MBMF_RL_data = read.csv('data/MBMF/MBMF_RL_model_extracted_parameters.csv', header=T)
app_data_temp = read.csv(habit_app_data, header=T)

# arange data
MBMF_RL_data = MBMF_RL_data[,names(MBMF_RL_data) != "X"] # remove an extra index column
colnames(MBMF_RL_data)[1] = 'subID'

# AN IMPORTANT FIX DUE TO MISTAKENLY ASSIGNING SUBJECT ID 341 IN THE APP TO 344 IN PART 3 (that includes the two-step task) 
# MBMF_RL_data[MBMF_RL_data$subID == 344,]$subID = 341
# The above is commented because it was fixed in another script already (when the model was running)

# extract relevant subjects:
MBMF_RL_data = MBMF_RL_data[MBMF_RL_data$subID %in% app_data_temp$subID,]
app_data_temp = app_data_temp[app_data_temp$subID %in% unique(MBMF_RL_data$subID),]

# add some relevant variables to the main table
for(subId in app_data_temp$subID){
  # Add devaluation measures
  MBMF_RL_data[MBMF_RL_data$subID == subId, 'Deval'] = app_data_temp[app_data_temp$subID==subId,'meanVal_relativeDiff_deval_SQRT']
  # Add group
  MBMF_RL_data[MBMF_RL_data$subID == subId, 'group'] = app_data_temp[app_data_temp$subID==subId,'group']
}
MBMF_RL_data[MBMF_RL_data$group=='short_training','training_length'] = 'short'
MBMF_RL_data[MBMF_RL_data$group!='short_training','training_length'] = 'long'

# effect coding and normalizing the data:
MBMF_RL_data$training_length[MBMF_RL_data$training_length=='short'] = -1
MBMF_RL_data$training_length[MBMF_RL_data$training_length=='long'] = 1
MBMF_RL_data$training_length = as.numeric(MBMF_RL_data$training_length)
MBMF_RL_data_unscaled = MBMF_RL_data
MBMF_RL_data$pers = as.numeric(scale(MBMF_RL_data$pers))
MBMF_RL_data$alpha = as.numeric(scale(MBMF_RL_data$alpha))
scaled_beta_1_MB = scale(MBMF_RL_data$beta_1_MB)
MBMF_RL_data$beta_1_MB = as.numeric(scaled_beta_1_MB)
scaled_beta_1_MF = scale(MBMF_RL_data$beta_1_MF)
MBMF_RL_data$beta_1_MF = as.numeric(scaled_beta_1_MF)
MBMF_RL_data$beta_2 = as.numeric(scale(MBMF_RL_data$beta_2))
scaled_Deval = scale(MBMF_RL_data$Deval)
MBMF_RL_data$Deval = as.numeric(scaled_Deval)

# The pers and alpha related registered analyses:
summary(rf1<-rfit(Deval ~ pers*training_length, data=MBMF_RL_data))
summary(rf2<-rfit(Deval ~ pers+training_length, data=MBMF_RL_data))
summary(rf3<-rfit(Deval ~ pers+pers:training_length, data=MBMF_RL_data))
summary(rf4<-rfit(Deval ~ training_length+pers:training_length, data=MBMF_RL_data))
drop.test(rf1,rf2) # interaction
drop.test(rf1,rf3) # main group
drop.test(rf1,rf4) # main factor
summary(rf1<-rfit(Deval ~ alpha*training_length, data=MBMF_RL_data))
summary(rf2<-rfit(Deval ~ alpha+training_length, data=MBMF_RL_data))
summary(rf3<-rfit(Deval ~ alpha+alpha:training_length, data=MBMF_RL_data))
summary(rf4<-rfit(Deval ~ training_length+alpha:training_length, data=MBMF_RL_data))
drop.test(rf1,rf2) # interaction
drop.test(rf1,rf3) # main group
drop.test(rf1,rf4) # main factor

# The same analysis for the other parameters extracted from the model (exploratory):
summary(rf1<-rfit(Deval ~ beta_1_MB*training_length, data=MBMF_RL_data))
summary(rf2<-rfit(Deval ~ beta_1_MB+training_length, data=MBMF_RL_data))
summary(rf3<-rfit(Deval ~ beta_1_MB+beta_1_MB:training_length, data=MBMF_RL_data))
summary(rf4<-rfit(Deval ~ training_length+beta_1_MB:training_length, data=MBMF_RL_data))
drop.test(rf1,rf2) # interaction
drop.test(rf1,rf3) # main group
drop.test(rf1,rf4) #main factor
summary(rf1<-rfit(Deval ~ beta_1_MF*training_length, data=MBMF_RL_data))
summary(rf2<-rfit(Deval ~ beta_1_MF+training_length, data=MBMF_RL_data))
summary(rf3<-rfit(Deval ~ beta_1_MF+beta_1_MF:training_length, data=MBMF_RL_data))
summary(rf4<-rfit(Deval ~ training_length+beta_1_MF:training_length, data=MBMF_RL_data))
drop.test(rf1,rf2) # interaction
drop.test(rf1,rf3) # main group
drop.test(rf1,rf4) #main factor
summary(rf1<-rfit(Deval ~ beta_2*training_length, data=MBMF_RL_data))
summary(rf2<-rfit(Deval ~ beta_2+training_length, data=MBMF_RL_data))
summary(rf3<-rfit(Deval ~ beta_2+beta_2:training_length, data=MBMF_RL_data))
summary(rf4<-rfit(Deval ~ training_length+beta_2:training_length, data=MBMF_RL_data))
drop.test(rf1,rf2) # interaction
drop.test(rf1,rf3) # main group
drop.test(rf1,rf4) #main factor


# --------- Plot [SCATTER]:
summary(rMF<-rfit(Deval ~ beta_1_MF*training_length, data=MBMF_RL_data))
ind_diff_data_plot = MBMF_RL_data_unscaled # get the data unscaled
# create fit for the short training:
grid_MBMF_Short = seq(min(MBMF_RL_data$beta_1_MF), max(MBMF_RL_data$beta_1_MF), by = .01)
fitShort = rMF$betahat[1]+
  rMF$betahat[2]*grid_MBMF_Short+
  rMF$betahat[3]*-1+ #-1 as this is how the short training was coded.
  rMF$betahat[4]*grid_MBMF_Short*-1 #-1 as this is how the short training was coded.
# use the scaled variables to get back to the original measures for plotting:
fit = fitShort * attr(scaled_Deval,'scaled:scale') + attr(scaled_Deval,'scaled:center')
grid_MBMF = grid_MBMF_Short * attr(scaled_beta_1_MF,'scaled:scale') + attr(scaled_beta_1_MF,'scaled:center')
line_dat = data.frame(grid_MBMF,fit)
line_dat['training_length']=-1

# create fit for the extensive training:
grid_MBMF_Long = seq(min(MBMF_RL_data$beta_1_MF), max(MBMF_RL_data$beta_1_MF), by = .01)
fitLong = rMF$betahat[1]+
  rMF$betahat[2]*grid_MBMF_Long+
  rMF$betahat[3]*1+ #1 as this is how the LONG training was coded.
  rMF$betahat[4]*grid_MBMF_Long*1 #1 as this is how the LONG training was coded.
# use the scaled variables to get back to the original measures for plotting:
fit = fitLong * attr(scaled_Deval,'scaled:scale') + attr(scaled_Deval,'scaled:center')
grid_MBMF = grid_MBMF_Long * attr(scaled_beta_1_MF,'scaled:scale') + attr(scaled_beta_1_MF,'scaled:center')
line_dat2 = data.frame(grid_MBMF,fit)
line_dat2['training_length']=1

#combine:
lines_DATA = rbind(line_dat, line_dat2)

#rename variables:
ind_diff_data_plot$training_length <- dplyr::recode(ind_diff_data_plot$training_length, "-1" = "Short","1" = "Extensive")
lines_DATA$training_length <- dplyr::recode(lines_DATA$training_length, "-1" = "Short","1" = "Extensive")
ind_diff_data_plot$training_length = factor(ind_diff_data_plot$training_length, levels=c('Short','Extensive'))
lines_DATA$training_length = factor(lines_DATA$training_length, levels=c('Short','Extensive'))

p <- ggplot(ind_diff_data_plot, aes(x=beta_1_MF, y=Deval,color=training_length)) +
  geom_point()+
  geom_line(aes(grid_MBMF, fit, colour=training_length), lines_DATA)+
  scale_x_continuous(breaks = breaks_extended(6)) +
  scale_y_continuous(breaks = breaks_extended(6)) +
  xlab(expression(beta * "  Model-free"))+
  ylab('Behavioral adaptation index')

pp <- p + theme_classic(base_size = 14, base_family = "Helvetica")+
  theme(strip.text.x = element_text(size = 16, face = "bold"),
        strip.text.y = element_text(size = 16, face = "bold"),
        strip.text = element_text(colour = 'black'),
        strip.background = element_rect(color="white", fill="white", linetype="solid"),
        axis.text.x = element_text(face="bold", size=12),
        axis.ticks.x = element_blank(),
        #legend.box.background = element_blank(),
        panel.grid.minor = element_blank(),
        panel.grid.major = element_line(color="gray", size=0.05),
        axis.title.x = element_text(size = 14, face = "bold"),
        axis.title.y = element_text(size = 14, face = "bold"),
        legend.title=element_text(size=12),
        legend.text=element_text(size=10),
        legend.position = c(0.89, 0.2),
        legend.background = element_rect(fill = "white", color = "gray"),
        aspect.ratio=0.8) 

pp$labels$colour <- "Training\nduration"
pp <- ggMarginal(pp, groupColour = TRUE, groupFill = TRUE)
pp
ggsave(file.path(figures_path,'MF_scatter.tiff'), pp, dpi = 100)
