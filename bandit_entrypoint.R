library(tidyverse)
library(extraDistr)

library(optparse)
library(aws.s3)

source('./helpers.R')

start_time<-Sys.time()

# library(doParallel)
# library(foreach)
# library(doRNG)

#### Parse Options
option_list <- list(
  make_option(c("-m", "--mean"), default = .2,
              help = "Effect Size (Cohens D)"), 
  make_option(c("-a", "--algorithm"), default = "ucb",
              help = "Bandit Strategy"), 
  make_option(c("-e", "--epsilon"), default = .05,
              help = "epsilong parameter"), 
  make_option(c("-c", "--ucbc"), default = 10,
              help = "Exploration Parameter"), 
  make_option(c("-p", "--prior_mean"), default = 0,
              help = "Prior mean"), 
  make_option(c("-v", "--prior_var"), default = 10,
              help = "prior variance"), 
  make_option(c("-d", "--prior_df_var"), default = 1,
              help = "prior df for variance"), 
  make_option(c("-k", "--prior_precision"), default = 1,
              help = "prior precision"), 
  make_option(c("-w", "--warmup"), default = 10,
              help = "Warmup Observations"), 
  make_option(c("-i", "--iter"), default = 1000,
              help = "Iterations through the bandit"), 
  make_option(c("-o", "--output"), default = 'mab-sim-jr',
              help = "What bucket to write to"),
  make_option(c("-s", "--samples"), default = 5000,
              help = "Samples of MC iteration")
  )

set.seed(54321)


opt_parser <- OptionParser(option_list=option_list)
opt <- parse_args(opt_parser)

print('parsed with options')
print(opt)

# # Register parallel processing
# n.cores <- parallel::detectCores()
# my.cluster <- parallel::makeCluster(
#   n.cores, 
#   type = "PSOCK"
# )

# doParallel::registerDoParallel(cl = my.cluster)

if(!opt$algorithm %in% c('epsilon', 'ucb', 'thompson')){
  print(opt$algorithm)
  stop('This algorithm name is not supported^^^')
  
}


# Set values 
population_mean<-c(0, opt$mean)
population_sd <- c(1, 1)
arms <- 2


data_helper_functions<-function_factory_data(population_mean, 
                                             population_sd)


if(opt$algorithm=="epsilon"){
  bandit_helper_functions<-function_factory_e_greedy(arms, opt$epsilon)
}else if(opt$algorithm=="ucb"){
  bandit_helper_functions<-function_factory_ucb(arms, opt$ucbc)
}else{
  bandit_helper_functions<-function_factory_thompson_sampling(arms = arms, 
                                                              prior_mean = rep(opt$prior_mean, 2), 
                                                              prior_var = rep(opt$prior_var, 2), 
                                                              prior_df_var = rep(opt$prior_df_var, 2), 
                                                              prior_precision = rep(opt$prior_precision, 2))

}

if(opt$algorithm=="epsilon"){
  object_name<-paste(opt$mean, opt$algorithm, opt$epsilon, opt$warmup, opt$iter, sep = '/')
}else if(opt$algorithm=="ucb"){
  object_name<-paste(opt$mean, opt$algorithm, opt$ucbc, opt$warmup, opt$iter, sep = '/')
}else{
  object_name<-paste(opt$mean, opt$algorithm, opt$prior_mean, opt$prior_var, opt$prior_precision, opt$prior_df_var, opt$warmup, opt$iter, sep = '/')
}


for (b in 1:opt$samples){
                     
                     if (b %% 5 == 0) print(paste('bootstrapped iteration:', b))
                     
                     sim<-MAB(warmup = data_helper_functions$warmup, 
                              data_generating_process = data_helper_functions$data_generating_process,
                              initialize_rewards = bandit_helper_functions$initialize_rewards,
                              update_rewards = bandit_helper_functions$update_rewards,
                              allocation_function = bandit_helper_functions$allocate_observations,
                              warmup_iter = opt$warmup, 
                              bandit_iter = opt$iter)
                     
                     sim$rewards$b<-b
                     sim$history$b<-b
                     
                     
                     retry(s3write_using(sim$rewards, write.csv, object = paste('reduced/rewards', object_name, b, 'output.csv', sep = '/'), bucket = opt$output))
                     retry(s3write_using(sim$history, write.csv, object = paste('reduced/history', object_name, b, 'output.csv', sep = '/'), bucket = opt$output))
 
                    gc()
                    rm(sim)
                   }


print(Sys.time()-start_time)
print('Finished!')
