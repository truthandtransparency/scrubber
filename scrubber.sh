#!/usr/bin/env bash

# scrubber.sh
# A simple wrapper around the necessary and appropriate docker commands to successfully run Scrubber.

function detect_directory(){
  # Check if necessary files are present. Send error if not.
  if [ ! -e "common_functions.sh" ] || [ ! -e "Dockerfile" ] || [ ! -e "scrub.sh" ]; then
    tput setaf 1 && tput smso
    echo -e "\n[!] ERROR: Please execute in the same directory as common_functions.sh, Dockerfile, and scrub.sh.\n"
    tput sgr0 && tput rmso
    exit 0
  fi

  # Load shared functions
  source common_functions.sh
}

function run_container(){
  # Replace host filepaths with container filepaths.
  params=$(echo "$@" | sed 's:'"$MAPPED_OUTPUT"':'"$DOCKER_OUTPUT_DIR"':g' | sed 's:'"$MAPPED_INPUT"':'"$DOCKER_INPUT_DIR"':g' | sed 's:--local ::g')
  
  # Start and run docker container with appropriate directories mapped and image used.
  eval docker run -it -u $(id -ur) --rm --name scrubber -v "$MAPPED_INPUT":"$DOCKER_INPUT_DIR" -v "$MAPPED_OUTPUT":"$DOCKER_OUTPUT_DIR" "$IMAGE" "$params"
}

function build_image(){
  # Build image locally rather than pull from Docker Hub.
  print_message "INFO" "Building the docker image locally. This may take a few minutes."
  docker build -t "$IMAGE" .
}

set -e

detect_directory
parse_args "$@"

# Check to see if --local was passed
if [ "$LOCAL_BUILD" -eq 1 ]; then
  build_image
fi

run_container "$@"
