FROM public.ecr.aws/docker/library/r-base:4.2.1

RUN apt-get update 
RUN apt-get install -y libv8-dev
RUN apt-get install -y libxml2-dev
RUN apt-get install -y build-essential 
RUN apt-get install -y libssl-dev 
RUN apt-get install -y libcurl4-openssl-dev
RUN apt-get install -y curl
RUN apt-get install -y unzip

RUN curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
RUN unzip awscliv2.zip
RUN ./aws/install

### Cloud dependencies
RUN Rscript --no-echo -e 'install.packages("aws.ec2metadata", repos = "https://cloud.R-project.org")'
RUN Rscript --no-echo -e 'install.packages("aws.s3", repos = "https://cloud.R-project.org")'

### Data Helpers
RUN Rscript --no-echo -e 'install.packages("tidyverse", repos = "https://cloud.R-project.org")'
### Extra Distributions for Thompson Sampling
RUN Rscript --no-echo -e 'install.packages("extraDistr", repos = "https://cloud.R-project.org")'

RUN Rscript --no-echo -e 'install.packages("doParallel", repos = "https://cloud.R-project.org")'
RUN Rscript --no-echo -e 'install.packages("foreach", repos = "https://cloud.R-project.org")'
RUN Rscript --no-echo -e 'install.packages("doRNG", repos = "https://cloud.R-project.org")'
RUN Rscript --no-echo -e 'install.packages("optparse", repos = "https://cloud.R-project.org")'

COPY ./bandit_entrypoint.R /opt/amazon/bandit_entrypoint.R
COPY ./helpers.R /opt/amazon/helpers.R
COPY ./run_bandit.sh /opt/amazon/run_bandit.sh


RUN chmod +x /opt/amazon/run_bandit.sh

WORKDIR /opt/amazon
