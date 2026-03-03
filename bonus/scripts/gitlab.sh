#!/bin/bash

RED='\033[31m'
GREEN='\033[32m'
BLUE='\033[34m'
NC='\033[0m' # No Color

#Get gitlab password
source /tmp/gitlab_vars.sh
echo -e "${GREEN}>>>>>> Gitlab root password: $GITLAB_PSW <<<<<<${NC}"

# Checking Gitab
echo -e "${BLUE}Checking Gitab is up and running...${NC}"
while ! curl -k -s "http://gitlab.local" > /dev/null; do
  sleep 2
done
echo -e "${BLUE}GitLab is ready${NC}"

# Creating a token with kubectl
echo -e "${BLUE}Creating gitlab root token${NC}"
ROOT_TOKEN=$(kubectl exec -n gitlab deploy/gitlab-toolbox -- gitlab-rails runner \
  "token = User.find_by_username('root').personal_access_tokens.create(scopes: ['api', 'read_repository'], name: 'argocd-token', expires_at: 365.days.from_now); puts token.token")

if [ -z "$ROOT_TOKEN" ]; then
  echo -e "${RED}Error : GitLab token cannot be created${NC}"
  exit 1
fi

echo -e "${GREEN}>>>>>> GitLab root token: $ROOT_TOKEN <<<<<<${NC}"

# Creating user sfraslin
echo -e "${BLUE}Creating user sfraslin...${NC}"
curl -s --request POST "http://localhost/api/v4/users" \
  --header "PRIVATE-TOKEN: $ROOT_TOKEN" \
  --data "name=Saina Fraslin&username=sfraslin&email=sfraslin@gitlab.local&password=Andr1amampandry!&skip_confirmation=true" > /dev/null
echo -e "${GREEN}Utilisateur sfraslin créé !${NC}"

# Creating repo
echo -e "${BLUE}Creating repository...${NC}"
curl -s --request POST "http://localhost/api/v4/projects" \
  --header "PRIVATE-TOKEN: $ROOT_TOKEN" \
  --data "name=sfraslin&visibility=public" > /dev/null
echo -e "${GREEN}Repo créé !${NC}"

# Adding files
echo -e "${BLUE}Adding files...${NC}"
TEMP_DIR=$(mktemp -d)
cp $PWD/bonus/gitlab_files/deployment.yaml $TEMP_DIR/
cp $PWD/bonus/gitlab_files/service.yaml $TEMP_DIR/
cp $PWD/bonus/gitlab_files/.gitlab-ci.yaml $TEMP_DIR/

cd $TEMP_DIR
git init
git config user.email "root@gitlab.local"
git config user.name "root"
git add .
git commit -m "Initial commit"
git remote add origin http://root:$ROOT_TOKEN@localhost/root/sfraslin.git
git push --set-upstream origin master:main
cd -
rm -rf $TEMP_DIR
echo -e "${GREEN}Fichiers poussés !${NC}"