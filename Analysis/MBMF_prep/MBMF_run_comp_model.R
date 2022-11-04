# This code runs the stan model, performs QA on its output, saves it and creates a csv file for later use.
# This code is based on codes published by Gillan et al. 2020 (codes in OSF: https://osf.io/w4yfp/)
# ----------------------------------------------------------------------
# Adapted by Rani Gera and last modified on November 2022
# ----------------------------------------------------------------------

# *******************************************************************************************************************************
# Load libraries, define parameters,
# *******************************************************************************************************************************
rm(list=ls())

library(rstan)
library(parallel)
rstan_options(auto_write = TRUE)
options(mc.cores = parallel::detectCores())

setwd(dirname(rstudioapi::getActiveDocumentContext()$path))
data <- read.csv("../data/MBMF/MBMF_data_for_RL_model.csv")
app_data = read.csv('../data/extracted_data/all_data_for_R.csv', header=T)
Rdata_file = "../data/MBMF/Gera_COMP_MODEL_OUTPUT.RData" # stores R variables (to save and load the model output)
output_file_path = "../data/MBMF/MBMF_RL_model_extracted_parameters.csv"

# *******************************************************************************************************************************
# Prepare and run the model
# *******************************************************************************************************************************
# AN IMPORTANT CORRECTION: BECAUSE SUBJECT 341 IN THE APP MISTAKENLY RECIEVED 344 TO PART 3 (TWO-STEP TASK AND QUESTIONNAIRES)
data[data$subID == 344,]$subID = 341
# extract relevant subjects (that were not excluded in the main task [i.e. the app]):
data = data[data$subID %in% app_data$subID,]

subs <- unique(data$subID)

nS <- length(subs)
MT <- 200
nT <- rep(0, nS) # initialize a vector of nS zeros (to store the number of trials).
choice1 <- array(0, dim = c(nS, MT)) # basically it is a 3D matrix initialized with zeros
choice2 <- array(0, dim = c(nS, MT)) # basically it is a 3D matrix initialized with zeros
state_at_t2 <- array(0, dim = c(nS, MT)) # basically it is a 3D matrix initialized with zeros
reward <- array(0, dim = c(nS, MT)) # basically it is a 3D matrix initialized with zeros

for (i in 1:nS) {
    nT[i] <- nrow(data[data$subID == subs[i], ])
    choice1[i, 1:nT[i]] <- data[data$subID == subs[i], ]$action_Stage1 - 1
    choice2[i, 1:nT[i]] <- data[data$subID == subs[i], ]$action_Stage2 - 1
    state_at_t2[i, 1:nT[i]] <- data[data$subID == subs[i], ]$state_Stage2 - 1
    reward[i, 1:nT[i]] <- data[data$subID == subs[i], ]$reward
}

standata <- list(nS = nS, MT = MT, nT = nT, choice1 = choice1, choice2 = choice2, state_at_t2 = state_at_t2, reward = reward)

fit <- stan(file = "MBMF_RL_Gera_model.stan", data = standata, iter = 4000, control = list(adapt_delta = 0.95, stepsize = .01))

save.image(file = Rdata_file, version = NULL, ascii = FALSE)

# *******************************************************************************************************************************
# Model QA
# *******************************************************************************************************************************
# Check convergence:
# ---------------------------------------------
summaryTable <- summary(fit)$summary
max(summaryTable[, "Rhat"])
min(summaryTable[, "Rhat"])
max(summaryTable[, "n_eff"])
min(summaryTable[, "n_eff"])

# Examine trace plots:
# -----------------------------------
traceplot(fit) # The first 10 (captures the group-level parameters)

# Then to test the per-subject parameters I used the following and each time changed the parameter, run and visually checked the PDF created:
# * use names(m) to see the names of all the parameters
pdf(file = "/Users/ranigera/Downloads/myplot.pdf",width=100, height=100)
traceplot(fit, pars=c('beta_1_MF')) # This is the parameter to change
dev.off()

# **********************************************************************************************************************************************
# Create a data file of the parameters extracted from the model
# [This part can be executed independently if the model has been already run and its output was saved before - namely the Rdata file is existed]
# **********************************************************************************************************************************************
load(Rdata_file)

m = rstan::extract(fit)

bySubj = data.frame(subj=unique(data$subID), pers=rep(0,(length(unique(data$subID)))), alpha=rep(0,(length(unique(data$subID)))), beta_1_MB=rep(0,(length(unique(data$subID)))), beta_1_MF=rep(0,(length(unique(data$subID)))),  beta_2=rep(0,(length(unique(data$subID)))))

for( i in 1:length(unique(data$subID))){
    bySubj[i,2:6] = c(mean(m$pers[,i]),mean(m$alpha[,i]),mean(m$beta_1_MB[,i]),mean(m$beta_1_MF[,i]), mean(m$beta_2[,i]))
}

write.csv(bySubj, output_file_path)
