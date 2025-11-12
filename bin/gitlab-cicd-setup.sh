#! bin/bash

if [ ! -f "~/.ssh/gitlab_deploy.pub" ]; then
  wget -O ~/.ssh/gitlab_deploy.pub https://raw.githubusercontent.com/vswb/gitlab-usages/refs/heads/main/gitlab_deploy.pub
  echo ~/.ssh/gitlab_deploy.pub >> ~/.ssh/authorized_keys
  rm -f ~/.ssh/gitlab_deploy.pub
  chmod 644 ~/.ssh/authorized_keys
fi
