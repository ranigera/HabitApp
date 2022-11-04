
// Created by Rani Gera at Oct 2021
// based on Sharp et al. (2016) and Gillan et al. (2020)
//

data {
	int<lower=1> nS;  // number of subjects
	int<lower=1> MT;  // maximum trials per subject
  int<lower=1> nT[nS];  // actual numbers of trials per subject, & session
	int<lower=0,upper=1> choice1[nS,MT];  // 0 / 1 *choice at 1st stage
	int<lower=0,upper=1> choice2[nS,MT];  // 0 / 1 *choice at 2nd stage
	int<lower=0,upper=2> state_at_t2[nS,MT];  // 1 / 2 *state of at t2 (after first choice); * The lower is zero because this are valus at the end of the array which are not in use (they appear in case a subject had less than 200 valid trials)
	int<lower=0,upper=1> reward[nS,MT];   // 1 / -1 (changed my stan.r file to make this 1,-1 as required) ~~~~~
}

parameters {
  // Group level parameters
  // ------------------------------------------------------------------
  // group level learning rate (no constraint here, that is done later)
  real alpha_m_group; // no constraint
  real<lower=0> alpha_s_group;
  // group level model-based beta (mean and SD)
  real<lower=0> beta_1_MB_m_group;
  real<lower=0> beta_1_MB_s_group;
  // group level TD-1 beta (mean and SD)
  real<lower=0> beta_1_MF_m_group;
  real<lower=0> beta_1_MF_s_group;
  // group level beta for second stage choices (mean and SD)
  real<lower=0> beta_2_m_group;
  real<lower=0> beta_2_s_group;
  // group level perseveration beta (mean and SD)
  real perservation_m_group;
  real<lower=0> perservation_s_group;
  // group level lambda for the SARSA(lambda) (mean and SD)
  //real lambda_m_group;
  //real<lower=0> lambda_s_group;
  
  // Subject level (raw) parameters
  // ------------------------------------------------------------------
  // per subject learning rates:
  vector[nS] alpha_subjects_raw; // again no constraint here ; this is the basis for transformation for alpha for each subject
  // per subject betas (inverse temperature of the first state MB and MF and of the 2nd state):
  vector[nS] beta_1_MB_subjects_raw;
  vector[nS] beta_1_MF_subjects_raw;
  vector[nS] beta_2_subjects_raw;
  // per subject perseveration:
  vector[nS] perservation_subjects_raw;
  // per subject lambda:
  //vector[nS] lambda_subjects_raw;
}

transformed parameters {
  //define transformed parameters
  vector<lower=0,upper=1>[nS] alpha; // This is the actual vector of alpha between 0 and one for each subject
  vector[nS] alpha_normal;
  vector[nS] beta_1_MB;
  vector[nS] beta_1_MF;
  vector[nS] beta_2;
  vector[nS] pers;
  //vector<lower=0,upper=1>[nS] lambda;
  //vector[nS] lambda_normal;

  //create transformed parameters using non-centered parameterization for all
  // and logistic transformation for alpha & lambda (range: 0 to 1)
  alpha_normal = alpha_m_group + alpha_s_group*alpha_subjects_raw;
  alpha = inv_logit(alpha_normal);
  beta_1_MB = beta_1_MB_m_group + beta_1_MB_s_group*beta_1_MB_subjects_raw;
  beta_1_MF = beta_1_MF_m_group + beta_1_MF_s_group*beta_1_MF_subjects_raw;
  beta_2 = beta_2_m_group + beta_2_s_group*beta_2_subjects_raw;
  pers = perservation_m_group + perservation_s_group*perservation_subjects_raw;
  //lambda_normal = lambda_m_group + lambda_s_group*lambda_subjects_raw;
  //lambda = inv_logit(lambda_normal);
  
  // note (from Brown et al. 2022: "Each RL parameter was estimated with a mean, scale, and individual error estimates (‘non-centered parameterization’(Betancourt & Girolami, 2015)).")
}


model {
  //define variables:
  // --------------------------------------
  real Q_MB[2];
  real Q_TD[2];
  real Q_2[2,2];
  int transition_counts[2,2]; // an array of transition counts indices [1,1] refer to action1 to state1, [1,2] refer to action1 to state2, [2,1] refer to action2 to state1, [2,2] refer to action2 to state2.
  real delta_1;
  real delta_2;
  int prev_choice;
  int unchosen_action_stage1;
  int unchosen_action_stage2;
  int unreached_state;

  // define priors:
  // --------------------------------------
  alpha_m_group ~ normal(0,2.5);
  alpha_s_group ~ cauchy(0,1);
  alpha_subjects_raw ~ normal(0,1);

  beta_1_MB_m_group ~ normal(0,5);
  beta_1_MB_s_group ~ cauchy(0,2);
  beta_1_MB_subjects_raw ~ normal(0,1);

  beta_1_MF_m_group ~ normal(0,5);
  beta_1_MF_s_group ~ cauchy(0,2);
  beta_1_MF_subjects_raw ~ normal(0,1);

  beta_2_m_group ~ normal(0,5);
  beta_2_s_group ~ cauchy(0,2);
  beta_2_subjects_raw ~ normal(0,1);

  perservation_m_group ~ normal(0,2.5);
  perservation_s_group ~ cauchy(0,1);
  perservation_subjects_raw ~ normal(0,1);

  //lambda_m_group ~ normal(0,2);
  //lambda_s_group ~ cauchy(0,1);
  //lambda_subjects_raw ~ normal(0,1);

  // run the model:
  // --------------------------------------
	for (s in 1:nS) { // iterate subjects
	  //initiaize values for subject s
    for (i in 1:2) {
      Q_TD[i]=.5;
      Q_MB[i]=.5;
      Q_2[1,i]=.5;
      Q_2[2,i]=.5;
      transition_counts[1,i]=0;
      transition_counts[2,i]=0;
    }
    prev_choice=0;

    for (t in 1:nT[s]) { // iterate trials
      // -----------------------------------------------------------------------
      // MODEL THE CHOICES according to current values
      // -----------------------------------------------------------------------
      choice1[s,t] ~ bernoulli_logit(beta_1_MB[s]*(Q_MB[2]-Q_MB[1]) + beta_1_MF[s]*(Q_TD[2]-Q_TD[1]) + pers[s]*prev_choice); // model choice/action probability at stage 1; done according to a softmax (implemented within as it is below, the softmax sort of done within the bernoulli_logit function)
      prev_choice = 2*choice1[s,t]-1; //1 if choice 2, -1 if choice 1; This encoding makes pers (stickiness) go to 1 when tend to repeat actions, to -1 when tend to switch actions and zero if there is not related effect to stickiness/perseveration or "unstickiness"/"unperseveration".
      choice2[s,t] ~ bernoulli_logit(beta_2[s]*(Q_2[state_at_t2[s,t],2]-Q_2[state_at_t2[s,t],1])); // model choice/action probability at stage 2; done according to a softmax (implemented within as it is below, the softmax sort of done within the bernoulli_logit function)

      // -----------------------------------------------------------------------
      // UPDATE Q-VALUES                 
      // -----------------------------------------------------------------------
      // TD Q-values & second stage values:
      // ------------------------------------------------

      //update chosen values
      Q_TD[choice1[s,t]+1] = (1-alpha[s]) * Q_TD[choice1[s,t]+1] + reward[s,t]; //This include the supposodely immediate and the update after the second stage for SARSA(lambda) when lambda=1.
      //Q_TD[choice1[s,t]+1] = Q_TD[choice1[s,t]+1] + alpha[s]*(delta_1+lambda[s]*delta_2); //This include the supposodely immediate and the update after the second stage for SARSA(lambda).
      Q_2[state_at_t2[s,t],choice2[s,t]+1] = (1-alpha[s]) * Q_2[state_at_t2[s,t],choice2[s,t]+1] + reward[s,t];
             
      // update unchosen TD Q-values & second stage values
      // ------------------------------------------------
      // get unchosen and unvisited actions:
      unchosen_action_stage1 = 2 - choice1[s,t]; // action 0 if took action 1; action 1 if took action 0
      unchosen_action_stage2 = 2 - choice2[s,t]; // action 0 if took action 1; action 1 if took action 0
      unreached_state = 3 - state_at_t2[s,t]; // if state 1 was reached then unreached = state 2 and vice versa
      // decay by 1-alpha:
      Q_TD[unchosen_action_stage1]= Q_TD[unchosen_action_stage1] * (1 - alpha[s]);
      Q_2[state_at_t2[s,t], unchosen_action_stage2] = Q_2[state_at_t2[s,t],unchosen_action_stage2] * (1 - alpha[s]);
      Q_2[unreached_state,1] = Q_2[unreached_state,1] * (1 - alpha[s]);
      Q_2[unreached_state,2] = Q_2[unreached_state,2] * (1 - alpha[s]);
      
      // update Q-values for MB strategies (according to the Bellman equation)
      // ------------------------------------------------
      //update transition counts
      transition_counts[choice1[s,t]+1,state_at_t2[s,t]] = transition_counts[choice1[s,t]+1,state_at_t2[s,t]] + 1;

      // update model-based values (based on evident transitions and task instructions) *there are two potential mappings (first stage a1 -> second stage s1 & first stage a2 -> second stage s2, or vice versa)
      Q_MB[1] = (transition_counts[1,1]+transition_counts[2,2]) > (transition_counts[1,2]+transition_counts[2,1]) ? fmax(Q_2[1,1],Q_2[1,2]) : fmax(Q_2[2,1],Q_2[2,2]);
      Q_MB[2] = (transition_counts[1,1]+transition_counts[2,2]) > (transition_counts[1,2]+transition_counts[2,1]) ? fmax(Q_2[2,1],Q_2[2,2]) : fmax(Q_2[1,1],Q_2[1,2]);

    }
  }
}
