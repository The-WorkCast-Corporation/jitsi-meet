set -e
VERSION="test"
PLAYBOOK_FILE="./jitsi-build.yml"
LOCAL_BUILD="jm.zip"
REGION="us-east-1"
TAG_TYPE="jitsi"
TAG_CLIENT="trialist3"

while getopts v:b:l:c: flag
do
    case "${flag}" in
        v) VERSION=${OPTARG};;
        b) BUCKET_LOCATION=${OPTARG};;
        l) LOCAL_BUILD=${OPTARG};;
        c) TAG_CLIENT=${OPTARG};;
    esac
done

npm install
make compile
make deploy
zip -r $LOCAL_BUILD .
aws s3 cp "${LOCAL_BUILD}" "s3://${BUCKET_LOCATION}/jitsi/${VERSION}/${LOCAL_BUILD}"

PLAYBOOK="$(awk '{printf "%s\\n", $0}' $PLAYBOOK_FILE  | sed -e 's/"/\\"/g')"

PARAMETERS="{ \"playbook\": [\"${PLAYBOOK}\"],\"playbookurl\": [\"\"],\"extravars\": [\"BUCKET_LOCATION=${BUCKET_LOCATION} OBJECT_LOCATION=jitsi/${VERSION}/${LOCAL_BUILD}\"],\"check\": [\"False\"],\"timeoutSeconds\": [\"3600\"]}"

COMMAND_ID=`aws ssm send-command --document-name "AWS-RunAnsiblePlaybook" --targets "[{\"Key\":\"tag:Type\",\"Values\":[\"${TAG_TYPE}\"]}, {\"Key\":\"tag:Client\",\"Values\":[\"${TAG_CLIENT}\"]}]" --document-version "1" --parameters "$PARAMETERS" --timeout-seconds 600 --max-concurrency "50" --max-errors "0" --region us-east-1 --query "Command.CommandId" | tr -d '"'`

# echo $COMMAND_ID

# while true;
# do
#   IS_INCOMPLETE=false
#   RESPONSES=(`aws ssm list-command-invocations --command-id $COMMAND_ID --details --query "CommandInvocations[*].CommandPlugins[*].ResponseCode[]" --region $REGION --output text`)
#   OUTPUTS=(`aws ssm list-command-invocations --command-id $COMMAND_ID --details --query "CommandInvocations[*].CommandPlugins[*].Output[]" --region $REGION --output text`)
#   # for out in "${OUTPUTS[@]}"
#   # do
#   #   echo "$out"
#   # done
#   echo ${RESPONSES[@]}
#   for res in "${RESPONSES[@]}"
#   do
#     echo "$res"
#     if [ "$res" != "0" ]; then
#       echo "Waiting..."
#       IS_INCOMPLETE=true
#     fi
#   done
#   if [ "$IS_INCOMPLETE" = false ] ; then
#     echo "Success!"
#     break
#   else
#     sleep 5s
#   fi
# done