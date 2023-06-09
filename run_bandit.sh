#!/bin/bash
echo 'starting bash script'

# Get the command line from the array job
# Assumes this is an array batch job
LINE=$((AWS_BATCH_JOB_ARRAY_INDEX + 1))

# Copy the array config from s3
### Assumes array_txt_arn is stored as an environmental variable
echo 'copying s3 files'
aws s3 cp ${ARRAY_TXT_ARN} ./array.txt

# Pull out the config for this specific array index
ARGS=$(sed -n ${LINE}p /opt/amazon/array.txt)

# Parse the arguments
m="$(cut -d'_' -f1 <<<"$ARGS")"
a="$(cut -d'_' -f2 <<<"$ARGS")"
e="$(cut -d'_' -f3 <<<"$ARGS")"
c="$(cut -d'_' -f4 <<<"$ARGS")"
p="$(cut -d'_' -f5 <<<"$ARGS")"
v="$(cut -d'_' -f6 <<<"$ARGS")"
d="$(cut -d'_' -f7 <<<"$ARGS")"
k="$(cut -d'_' -f8 <<<"$ARGS")"
w="$(cut -d'_' -f9 <<<"$ARGS")"
i="$(cut -d'_' -f10 <<<"$ARGS")"
s="$(cut -d'_' -f11 <<<"$ARGS")"
o="$(cut -d'_' -f12 <<<"$ARGS")"


# Execute the Script
Rscript /opt/amazon/bandit_entrypoint.R -m ${m} -a ${a} -e ${e} -c ${c} -p ${p} -v ${v} -d ${d} -k ${k} -w ${w} -i ${i} -o ${o} -s ${s}

