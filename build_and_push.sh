# The name of our algorithm
algorithm_name=mabrepo

# extract necessary information to login to ECR and push the image
account=$(aws sts get-caller-identity --query Account --output text)

region=${region:-us-east-1}

fullname="${account}.dkr.ecr.${region}.amazonaws.com/${algorithm_name}:latest"

ecr_address="${account}.dkr.ecr.us-east-1.amazonaws.com"

# If the repository doesn't exist in ECR, create it.

aws ecr describe-repositories --repository-names "${algorithm_name}" > /dev/null 2>&1

if [ $? -ne 0 ]
then
    aws ecr create-repository --repository-name "${algorithm_name}" > /dev/null
fi


# Build the docker image locally with the image name and then push it to ECR
# with the full name.
aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin 763104351884.dkr.ecr.us-east-1.amazonaws.com
docker build  -t ${algorithm_name} . --build-arg REGION=${region}
docker tag ${algorithm_name} ${fullname}


aws ecr get-login-password --region us-east-1 | docker login -u AWS --password-stdin ${ecr_address}
docker push ${fullname}