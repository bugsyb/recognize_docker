#!/bin/bash

set -e

GIT_UPDATE_ON_EACH=false
WEBFRONTEND=apache		# select frontend, apache or fpm, needs to be Debian base as nvidia is (Alpine is a no go - pain to get tensor on Alpine)
PHP_BASE=8.2/bookworm		# currently adjust as default for NC 26 image 8.2/bookworm
NC_BASE=26			# NC Base version, exact patch/release changes on git pulls

OVERWRITE_NEXTCLOUD_TAGS=n
CUSTOM_ADDONS=custom-addons
NEXTCLOUD_TAGS="-t local/nextcloud:latest -t local/nextcloud"

BUILD_GPU=true
BUILD_CPU=false

# potential adjustments, builds fine as of 2023.10.16
TENSOR_IMAGE=nvcr.io/nvidia/tensorflow
TENSOR_VER=22.03-tf2-py3

## rarely needed to be touched
PHP_REPO=https://github.com/docker-library/php
PHP_DIR=php
NC_REPO=https://github.com/nextcloud/docker
NC_DIR=nextcloud

################################################################
adjust_build_vars(){
export PHP_VER=${PHP_BASE}/$WEBFRONTEND
export NC_VER=${NC_BASE}/$WEBFRONTEND
}


process_cmdline(){
  # Process command-line arguments using a case structure
  while [[ $# -gt 0 ]]; do
    case "$1" in
      -w|--webfront)
        if [ -n "$2" ]; then
	    WEBFRONTEND="$2"
	else 
	    echo "No version supplied for $0, i.e. $WEBFRONTEND"
	    exit 1
	fi
	shift 2
        ;;
      -p|--php-version)
        if [ -n "$2" ]; then
	    PHP_BASE="$2"
	else 
	    echo "No version supplied for $0, i.e. $PHP_BASE"
	    exit 1
	fi
        shift 2
        ;;
      -n|--nextcloud)
        if [ -n "$2" ]; then
	    NC_BASE="$2"
	else 
	    echo "No version supplied for $0, i.e. $NC_BASE"
	    exit 1
	fi
        shift 2
        ;;
      -h|--help)
        echo "Usage: $0 [-n|--nextcloud <version-tag>] [-p|--php-version <version-tag>] [-w|--webfront <string>] [-h|--help]"
        exit 0
        ;;
      *)
        echo "Error: Unknown option or argument '$1'."
        exit 1
        ;;
    esac
  done
}

repo_latest(){
  repo_url=$1
  local_dir=$2

  # In case we want to skip git pull (especially at troubleshooting time)
  if [ "$GIT_UPDATE_ON_EACH" == "false" ] && [ -d $2 ] ;then 
    return
  fi
  # Check if the local repository exists
  if [ -d "$local_dir/.git" ]; then
    # If it exists, fetch changes from the remote repository
    cd "$local_dir"
    git fetch origin
    git pull origin master  # Replace 'master' with the appropriate branch name
  else
    # If it doesn't exist, clone a fresh copy
    git clone "$repo_url" "$local_dir"
  fi
}

tag_from_repo(){
  echo "$1"|sed -e 's/\//-/g'
}

php_inverse_tag_order(){
  echo "$1"|awk -F '-' 'BEGIN{OFS=FS} {print $1, $3, $2}'
}

base_for(){
  FROMS="$(grep "FROM " $1)"
  FROMS_CNT=$(echo "$FROMS"|wc -l)

  if [ $FROMS_CNT -eq 1 ];then
      echo "${FROMS##* }"
  else
      exit 1
  fi
}

nc_build_ver(){
  FROMS=$(grep "ENV NEXTCLOUD_VERSION" ${NC_DIR}/${NC_VER}/Dockerfile)
  FROMS_CNT=$(echo "$FROMS"|wc -l)
  if [ $FROMS_CNT -eq 1 ];then
      echo "$FROMS"| awk '{print $3}'
  else
      exit 1
  fi

}

nc_custom_tags(){
  if [ "$OVERWRITE_NEXTCLOUD_TAGS" == "y" ]; then
    NCTAGS="$NEXTCLOUD_TAGS"
  else
    NCTAGS=""
  fi
  echo "$NCTAGS"
}

# Function to split and tag an image with multiple tags
split_and_tag() {
  source_image="$1"
  original_string="${@:2}"

  # Split the string into an array of tags
  IFS=" " read -ra tags <<< "$original_string"

  # Tag the source image with each tag
  for tag in "${tags[@]}"; do
    docker tag "$source_image" "$tag"
  done
}




build_gpu(){
  echo "#######
#
## ACHTUNG!!! local overlay of public tags (debian bookworm slim & PHP)
#
#
#  I'll sleep for 10s.
#######"

  sleep 10
  docker pull $TENSOR_IMAGE:$TENSOR_VER
  docker tag $TENSOR_IMAGE:$TENSOR_VER $(base_for php/$PHP_VER/Dockerfile)
  # get first tensor!!! as bookworm slim

  DOCKER_BUILDKIT=1 docker build -t php:$(php_inverse_tag_order $(tag_from_repo $PHP_VER)) -t local/php:$(php_inverse_tag_order $(tag_from_repo $PHP_VER)) ${PHP_DIR}/${PHP_VER}/.
  
  
  
  #DOCKER_BUILDKIT=1 docker build -t nextcloud:$(tag_from_repo $NC_VER) -t nextcloud:${NC_VER_BUILD}-${##*/} ${NC_DIR}/${NC_VER}
  #DOCKER_BUILDKIT=1 docker build -t nextcloud:$(tag_from_repo $NC_VER) -t nextcloud:${NC_VER_BUILD}-${NC_VER##*/} -t local/nextcloud:${NC_VER_BUILD}-${NC_VER##*/} ${NC_DIR}/${NC_VER}
  DOCKER_BUILDKIT=1 docker build -t local/nextcloud:$(tag_from_repo $NC_VER)-tensor -t local/nextcloud:${NC_VER_BUILD}-${NC_VER##*/}-tensor ${NC_DIR}/${NC_VER}
  
  # custom
  if [ -n "$CUSTOM_ADDONS" ]; then
      DOCKER_BUILDKIT=1 docker build  --build-arg NCBASE=local/nextcloud:${NC_VER_BUILD}-${NC_VER##*/}-tensor -t local/nextcloud:$(tag_from_repo $NC_VER)-tensor-custom \
  				-t local/nextcloud:${NC_VER_BUILD}-${NC_VER##*/}-tensor-custom \
  				 $(nc_custom_tags) $CUSTOM_ADDONS
  #				-t local/nextcloud:${NC_VER%%/*}-custom \
  fi
  if [ "$OVERWRITE_NEXTCLOUD_TAGS" == "y" ]; then 
      split_and_tag local/nextcloud:${NC_VER_BUILD}-${NC_VER##*/}-tensor ${NEXTCLOUD_TAGS//-t /}
  fi
}



build_cpu(){
  # build-non-gpu image
  #DOCKER_BUILDKIT=1 docker build -t nextcloud:$(tag_from_repo $NC_VER)-custom -t local/nextcloud:${NC_VER_BUILD}-${NC_VER##*/}-custom ${NC_DIR}/${NC_VER}
  DOCKER_BUILDKIT=1 docker build  --build-arg NCBASE=nextcloud:${NC_BASE}-${NC_VER##*/} -t local/nextcloud:$(tag_from_repo $NC_VER)-custom \
  				-t local/nextcloud:${NC_VER_BUILD}-${NC_VER##*/}-custom \
  				 $(nc_custom_tags) $CUSTOM_ADDONS

  #${NC_VER_BUILD}-${NC_VER##*/}
}

################################################################


process_cmdline "$@"

adjust_build_vars
repo_latest $PHP_REPO $PHP_DIR
repo_latest $NC_REPO $NC_DIR
# get exact Nextcloud version
NC_VER_BUILD=$(nc_build_ver)
[[ $BUILD_GPU == true ]] && build_gpu
[[ $BUILD_CPU == true ]] && build_cpu
