#!/bin/bash

{
  echo "alias ll='ls -l'"
  echo "alias vim=vi"
} >> ~/.bashrc

# Install Vim
sudo apt-get update
sudo apt-get install -y vim
