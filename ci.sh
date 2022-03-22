#!/bin/sh
export VERSION=$(git rev-parse HEAD | cut -c1-7)

if [ -f .env.auth ]
then
  export $(cat .env.auth | sed 's/#.*//g' | xargs)
fi



docker login registry.gitlab.com -u $GITLAB_USERNAME  -p $GITLAB_PAT

export NEW_IMAGE="registry.gitlab.com/${GITLAB_USERNAME}b/gitops-application-builder:${VERSION}" 

docker build -t ${NEW_IMAGE} .
docker push ${NEW_IMAGE}


GITHUB_REPO=gitops-with-compose-deployer
GITHUB_REPO_URL=https://${GITHUB_USERNAME}:${GITHUB_PAT}@github.com/${GITHUB_USERNAME}/${GITHUB_REPO}.git

git clone $GITHUB_REPO_URL
cd ${GITHUB_REPO}


cat <<EOF > /tmp/new-docker-compose.applications.yaml
version: "3"
services:
  pod_health:
    container_name: pod_health
    image: ${NEW_IMAGE}
    environment:
      - PORT=3000
    ports:
      - "4600:3000"
    


networks:
  default:
    external:
      name: applications_dev
EOF


mv /tmp/new-docker-compose.applications.yaml ./dev/applications/docker-compose.applications.yaml


git config --local user.email "panupong-ci@github.com"
git config --local user.name "Panupong CI"

git add .
git commit -m "[ADD] - docker-compose.applications.yaml $VERSION"
git checkout -b release-${VERSION}
git push origin -f release-${VERSION}

cd ..
rm -rf ${GITHUB_REPO}