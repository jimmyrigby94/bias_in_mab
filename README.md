# bias_in_mab
This repository contains supplemental materials for a manuscript written by Rigby &amp; Curuksu addressing ATE bias in adaptively sampled experiments such as multiarmed bandits. 

The repository contains 5 primary files. 

bandit_entrypoint.R: The primary entrypoint used to generate data sampled by two-armed bandit assuming each arm's rewards are sampled from independent gaussians. 

Run the following for a description of the CLI arguments

```
RScript bandit_entrypoint.R --help

```

```
Usage: bandit_entrypoint.R [options]


Options:
        -m MEAN, --mean=MEAN
                What is the Effect Size (Cohens D) of the optimal arm?

        -a ALGORITHM, --algorithm=ALGORITHM
                Which bandit strategy should be used? ['epsilon', 'ucb', 'thompson']

        -e EPSILON, --epsilon=EPSILON
                If epsilon-greedy, what proportion of samples should explore?

        -c UCBC, --ucbc=UCBC
                If UCB, what is the hyperparameter (c) controlling exploration levels?

        -p PRIOR_MEAN, --prior_mean=PRIOR_MEAN
                If thompson sampling, what is the prior mean (constrained across both arms)

        -v PRIOR_VAR, --prior_var=PRIOR_VAR
                If thompson sampling, what is the prior variance (constrained across both arms)

        -d PRIOR_DF_VAR, --prior_df_var=PRIOR_DF_VAR
                If thompson sampling, what is the prior degrees of freedom (constrained across both arms)

        -k PRIOR_PRECISION, --prior_precision=PRIOR_PRECISION
                If thompson sampling, what is the prior variance (constrained across both arms)

        -w WARMUP, --warmup=WARMUP
                How many warmup observations should be sampled at random?

        -i ITER, --iter=ITER
                How many total samples should the MAB generate?

        -o OUTPUT, --output=OUTPUT
                Which S3 bucket should the output be written to?

        -s SAMPLES, --samples=SAMPLES
                How many Monte Carlo samples should be drawn using this configuration?

        -h, --help
                Show this help message and exit
```


helpers.R: A set of helper functions that facilitate the MAB simulation. 

Dockerfile: A dockerfile that defines an image that may be used to run the script and can be deployed to a cloud environment. 

build_and_push.sh: A bash script to build a docker container and deploy it to Amazon ECR given the user's credentials. Assumes AWS CLI has been installed and the user has provided the CLI with the necessary credentials. 

run_bandit.sh: A bash script for running the simulation as an array job. Assumes that cli parameters were passed as a flat text file delimitted by an underscore. Each line representing a simulation condition and the array job indexes the simulations. 


