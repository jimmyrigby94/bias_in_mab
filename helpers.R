### Define Helper Functions



MAB<-function(warmup, data_generating_process, initialize_rewards, update_rewards, allocation_function, warmup_iter, bandit_iter){
 
  #' MAB: Generic wrapper for a MAB process
  #'
  #' @param warmup How should the algorithm sample initially (function)
  #' @param data_generating_process An function that returns the reward given an action (function)
  #' @param initialize_rewards How rewards for each arm should be initialized based on the warmup (function)
  #' @param update_rewards How the algorithm shoiuld update a reward (function)
  #' @param allocation_function How the next observation should be allocated based on reward (function)
  #' @param warmup_iter How many samples should be taken using the warmup initialization (int)
  #' @param bandit_iter How many samples should be taken using the bandit algorithm's allocation function (int)
  #'
  #' @return A list containing the sampling process (history) and the expected rewards (rewards)
  #' @export
  #'
  #' @examples

  # create a warmup for the algorithm
  history<-warmup(warmup_iter)
  
  # estimate the rewards based on the history
  rewards<-initialize_rewards(history)
  
  # adaptively sample based on the rewards
  for (i in (warmup_iter+1):bandit_iter){
    treatment<-allocation_function(rewards)
    
    new_data<-data_generating_process(treatment)
    
    # update the history
    history<-bind_rows(history, new_data)
    
    # update the rewards
    rewards<-update_rewards(rewards, new_data)
  }
  
  return(
    list(rewards = rewards, 
         history = history
    )
  )
}


function_factory_data<-function(population_means, population_sds){
  #' function_factory_data
  #' 
  #' Create helper functions for defining the data generating process and warmup function 
  #'
  #' @param population_means numeric vector defineing reward distribution means with a length equal to the number of arms.
  #' @param population_sds numeric vector defineing reward distribution standard deviations with a length equal to the number of arms.
  #'
  #' @return
  #' @export
  #'
  #' @examples
  #' 
  ### Define the data generating process
  data_generating_process<-function(arm_id){
    data.frame(
      condition = arm_id, 
      reward = rnorm(1, population_means[arm_id], population_sds[arm_id])
    )
  }
  
  # define the warmup
  warmup<-function(warmup_iter){
    tmp<-data.frame(
      condition = rep(sample(1:length(population_means), replace = FALSE), length.out = warmup_iter))%>%
      mutate(mean = population_means[condition], 
             sd = population_sds[condition])%>%
      group_by(condition)%>%
      mutate(reward = rnorm(n(), mean, sd))%>%
      select(-mean, -sd)%>%
      ungroup()
    
    return(tmp)
  }
  
  # return a list of helper functions
  return(
    list(
      data_generating_process = data_generating_process, 
      warmup = warmup
    )
  )
}


function_factory_e_greedy<-function(arms, epsilon){
  #' function_factory_e_greedy
  #' 
  #' A function factory to create epsilon greedy helper functions 
  #' that initialize rewards, update rewards and allocate new observations based on rewards
  #'
  #' @param arms the number of arms to sample (int)
  #' @param epsilon the proportion of samples that should be explored
  #'
  #' @return list of functions that initialize rewards, update rewards and allocate new observations based on rewards to be used in MAB wrapper 
  #' @export
  #'
  #' @examples
  
  initialize_rewards<-function(history){
    expected_rewards<-history%>%
      group_by(condition)%>%
      summarise(expected_reward = mean(reward), 
                n = n())%>%
      ungroup()
    
    return(expected_rewards)
  }
  
  update_rewards<-function(reward, new_data){
    # Identify the arm pulled
    update_arm<-new_data$condition[1]
    
    # Identify necessary information to update arm
    n_old<-reward[update_arm, 'n']
    n_new<-n_old+1
    old_reward<-reward[update_arm, 'expected_reward']
    new_reward<-new_data$reward[1]
    
    # apply update
    reward[update_arm, 'expected_reward']<-n_old/n_new*old_reward+1/n_new*new_reward
    reward[update_arm, 'n']<-n_new
    
    return(reward)
  }
  

  allocate_observations<-function(rewards){

    explore <- rbinom(1,1,epsilon)
    
    if (!explore) {
      allocation_condition<-which.max(rewards$expected_reward)
    } else {
      allocation_condition<-sample(1:arms, 1)
    }
    
    return(allocation_condition)
  }
  
  return(list(
    initialize_rewards = initialize_rewards,
    update_rewards = update_rewards, 
    allocate_observations = allocate_observations
  )
  )
}

function_factory_ucb<-function(arms, c){
  
  #' function_factory_e_greedy
  #' 
  #' A function factory to create UCB helper functions 
  #' that initialize rewards, update rewards and allocate new observations based on rewards
  #'
  #' @param arms the number of arms to sample (int)
  #' @param c tuning parameter to increase exploration
  #'
  #' @return list of functions that initialize rewards, update rewards and allocate new observations based on rewards to be used in MAB wrapper 
  #' @export
  #'
  #' @examples
  #
  initialize_rewards<-function(history){
    expected_rewards<-history%>%
      group_by(condition)%>%
      summarise(expected_reward = mean(reward), 
                n = n())%>%
      ungroup()%>%
      mutate(ucb = expected_reward+c*sqrt((log(sum(n))/n)))%>%
      arrange(condition)%>%
      ungroup()
  }
  
  update_rewards<-function(reward, new_data){
    
    # Identify the arm pulled
    update_arm<-new_data$condition[1]
    
    # Identify necessary information to update arm
    n_old<-reward[update_arm, 'n']
    n_new<-n_old+1
    reward[update_arm, 'n']<-n_new
    old_reward<-reward[update_arm, 'expected_reward']
    new_reward<-new_data$reward[1]
    total_n<-sum(reward$n)
    
    # apply update
    reward[update_arm, 'expected_reward']<-n_old/n_new*old_reward+1/n_new*new_reward
    reward[update_arm, 'ucb']<-reward[update_arm, 'expected_reward'] + c*sqrt((log(sum(total_n))/n_new))
    
    return(reward)
  }
  
  allocate_observations<-function(rewards){
    
    allocation_condition<-which.max(rewards$ucb)
    
    
    return(allocation_condition)
  }
  
  return(list(
    initialize_rewards = initialize_rewards,
    update_rewards = update_rewards, 
    allocate_observations = allocate_observations
  )
  )
}

#' Title
#'

function_factory_thompson_sampling<-function(arms, prior_mean, prior_var, prior_df_var, prior_precision){
  #' function_factory_thompson_sampling
  #' 
  #' A function factory to create epsilon greedy helper functions 
  #' that initialize rewards, update rewards and allocate new observations based on rewards
  #' thompson sampling is implemented as in Gelman 2014
  #' 
  #' @param arms: number of arms (int)
  #' @param prior_mean numeric vector of prior means with lenth equal to arms
  #' @param prior_var numeric vector of prior variance with lenth equal to arms
  #' @param prior_df_var numeric vector of prior degrees of freedom with lenth equal to arms
  #' @param prior_precision numeric vector of prior variance with lenth equal to arms
  #'
  #' @return list of functions that initialize rewards, update rewards and allocate new observations based on rewards to be used in MAB wrapper 
  #' @export
  #'
  #' @examples
  
  ### Following Gelman et al. 2014, using conjugate priors for an analytic posterior distribution
  ### prior_mean = mu0
  ### prior_precision = kappa  ### slight misnomer in argument name larger values = more precise
  ### prior_df_var = nu
  ### prior_var = signa^2_0
  
  if(
    !all(c(length(prior_mean)==arms,
           length(prior_var)==arms,
           length(prior_df_var)==arms,
           length(prior_precision)==arms))
  ){
    stop("Check that priors are concsistent with # arms")
  }
  
  # solve for posterior of mu
  initialize_reward<-function(history){
    
    ### Estimate sample statistics
    history%>%
      group_by(condition)%>%
      summarise(expected_reward = mean(reward), 
                reward_variance = var(reward),
                n = n())%>%
      ungroup()%>%
      arrange(condition)%>%
      
      ### Adds prior information
      mutate(prior_mean = prior_mean, 
             prior_var = prior_var, 
             prior_df_var = prior_df_var, 
             prior_precision = prior_precision)%>%
      
      ### Estimate posterior information (see Gelman et al., pg. 68)
      mutate(post_mean_mean = prior_precision/(prior_precision+n) * prior_mean+ 
               n/(prior_precision+n)*expected_reward, 
             
             post_precision_mean = prior_precision+n, 
             
             post_df_var = prior_df_var+n, 
             
             post_ss = prior_df_var*prior_var+ #prior ss
               (n-1)*reward_variance+ # observed ss
               (prior_precision*n)/(prior_precision+n)*(expected_reward-prior_mean)^2, # weighted deviation of prior from obserrved mean
             post_var = post_ss/post_df_var
      )
  }
  
  update_rewards<-function(reward, new_data){
    
    # Identify the arm pulled
    update_arm<-new_data$condition[1]
    
    # Identify necessary information to update arm
    n_old<-reward[update_arm, 'n']
    n_new<-n_old+1
    
    old_reward<-reward[update_arm, 'expected_reward']
    new_reward<-new_data$reward[1]
    
    old_var<-reward[update_arm, 'reward_variance']
    
    
    # Extract Priors
    prior_mean <- reward[update_arm, 'prior_mean']
    prior_var <- reward[update_arm, 'prior_var']
    prior_precision <- reward[update_arm, 'prior_precision']
    prior_df_var <- reward[update_arm, 'prior_df_var']
    
    
    # apply update to expected reward
    new_expected_reward<-n_old/n_new*old_reward+1/n_new*new_reward
    reward[update_arm, 'expected_reward']<-new_expected_reward
    reward[update_arm, 'n']<-n_new
    new_reward_var<-n_old/n_new*old_var+1/n_old*(new_reward-reward[update_arm, 'expected_reward'])^2
    reward[update_arm, 'reward_variance']<-new_reward_var
    
    # Apply update to posteriors
    reward[update_arm, 'post_mean_mean'] <- prior_precision/(prior_precision+n_new) * prior_mean+ 
      n_new/(prior_precision+n_new)*new_expected_reward
    
    reward[update_arm, 'post_precision_mean'] <- prior_precision+n_new
    reward[update_arm, 'post_df_var'] <- prior_df_var+n_new
    
    reward[update_arm, 'post_ss'] <- prior_df_var*prior_var+
      (n_old)*new_reward_var+
      (prior_precision*n_new)/(prior_precision+n_new)*(new_expected_reward-prior_mean)^2
    
    reward[update_arm, 'post_var'] <- reward[update_arm, 'post_ss']/reward[update_arm, 'post_df_var']
    
    return(reward)
  }
  
  allocate_observations<-function(rewards){
    
    rewards<-rewards%>%
      group_by(condition)%>%
      
      mutate(
        # sample from the posterior distribution of the variance
        sample_var = extraDistr::rinvchisq(n(), post_df_var, post_var),
        # Sample from the posterio distribution of the average
        sample_mu = rnorm(n(), post_mean_mean, sqrt(sample_var/post_precision_mean))
      )%>%
      ungroup()
    
    allocation_condition<-which.max(rewards$sample_mu)
    
    return(allocation_condition)
  }
  
  return(list(
    initialize_rewards = initialize_reward,
    update_rewards = update_rewards, 
    allocate_observations = allocate_observations
  )
  )
  
}

retry <- function(a, max = 3, init = 0){
  # error handling for s3 writeout which can fail if too many concurrent calls are made. 
  suppressWarnings( 
    tryCatch({
      if(init<max) a
    }, 
    error = function(e){
      print(init) 
      Sys.sleep(3)
      retry(a, max, init = init+1)
    }
    )
  )
}