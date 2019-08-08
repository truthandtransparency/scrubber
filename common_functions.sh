#!/usr/bin/env bash

# common_functions.sh
# Functions used by both scrubber.sh and scrub.sh.

# Print the help screen
function print_help(){
  echo -e "USAGE:\nscrubber <options> -i|--input [input_file_path] -o|--output [output_file_path]

  Options:
  --local: Build docker image locally rather than pulling form Docker Hub
  -l, --language <language>: Language for PDF OCR (https://github.com/tesseract-ocr/tesseract/blob/master/doc/tesseract.1.asc#languages)
  -a, --achromatic: Remove color from PDF to avoid Reality Winner's situation. Cannot be set with -m or --merge
  -r, --redact: Just separate the pages of the PDF into PNGs for redactions
  -m, --merge: Just merge the PNGs
  -b, --batch: Batch mode. Provide directories of PDFs as --input and output to directory. Original will be renamed with *+original.pdf.
  -h, --help: Print this help text
  -i, --input: PDF to scrub
  -o, --output: Filepath for clean PDF
  "

  exit 0
}

# Standardize error printing
function print_message(){
  reset_color=$(tput sgr0; tput rmso)

  if [[ "$1" == "ERROR" ]]; then
    set_color=$(tput setaf 1; tput smso)
    symbol="!"
  elif [[ "$1" == "INFO" ]]; then
    set_color=$(tput setaf 2; tput smso)
    symbol="*"
  fi
  
  echo -e "\n${set_color}["$symbol"] "$1": $2${reset_color}\n"
  if [[ "$1" == "ERROR" ]]; then
    print_help
  fi
}

# Parse command line arguments
function parse_args(){

  # set default arugments
  LANGUAGE="eng"
  ACHROMATIC=0
  REDACT=0
  MERGE=0
  BATCH_MODE=0
  LOCAL_BUILD=0
  INPUT_FILE=""
  OUTPUT_FILE=""
  INPUT_DIR=""
  OUTPUT_DIR=""
  MAPPED_INPUT=""
  MAPPED_OUTPUT=""
  DOCKER_INPUT_DIR="/input"
  DOCKER_OUTPUT_DIR="/output"
  IMAGE="truthandtransparency/scrubber:latest"

  while [[ "$#" -gt 0 ]]; do
    case "$1" in
      --local)
        LOCAL_BUILD=1
        IMAGE="scrubber-local"
        shift;;
      -a|--achromatic)
        ACHROMATIC=1;
        shift;;
      -r|--redact)
        REDACT=1;
        # Can't have --redact and --merge at the same time
        if [ "$REDACT" -eq 1 ] && [ "$MERGE" -eq 1 ]; then
          print_message "ERROR" "Invalid arguments: First redact, then merge."
        fi;
        shift;;
      -m|--merge)
        MERGE=1;
        # Can't have --redact and --merge at the same time
        if [ "$REDACT" -eq 1 ] && [ "$MERGE" -eq 1 ]; then
          print_message "ERROR" "Invalid arguments: First redact, then merge."
        fi;
        shift;;
      -b|--batch)
        BATCH_MODE=1;
        shift;;
      -h|--help)
        print_help;
        shift;;
      -l|--language)
        LANGUAGE="$2";
        shift;
        shift;;
      -i|--input)
        # Check to see if directory is passed to --input
        if [ -d "$2" ]; then
          MAPPED_INPUT="$2"
          # Can't pass directory and not -b or --batch
          if [ "$BATCH_MODE" -eq 0 ]; then
            print_message "ERROR" "Must indicate -b or --batch when passing a directory as -i or --input."
          fi;
          # Check for trailing slash. Add one if needed.
          if [[ "${2: -1}" != "/" ]]; then
            INPUT_DIR="$2/"
          else
            INPUT_DIR="$2"
          fi
        # Check to see if file is passed to --input
        elif [ -f "$2" ]; then
          INPUT_FILE="$2";
          MAPPED_INPUT=$(dirname "$2")
          # Can't pass file when calling -b or --batch
          if [ "$BATCH_MODE" -eq 1 ]; then
            print_message "ERROR" "Must pass directory as --input when using batch mode."
          fi;
        fi;
        shift;
        shift;;
      -o|--output)
        # Check to see if directory is passed to --ouput
        if [ -d "$2" ]; then
          MAPPED_OUTPUT="$2"
          # Can't pass directory and not -b or --batch
          if [ "$BATCH_MODE" -eq 0 ]; then
            print_message "ERROR" "Must indicate -b or --batch when passing a directory as -o or --output."
          fi;
          # Check for trailing slash. Add one if needed.
          if [[ "${2: -1}" != "/" ]]; then
            OUTPUT_DIR="$2/"
          else
            OUTPUT_DIR="$2"
          fi
        else
          OUTPUT_FILE="$2";
          MAPPED_OUTPUT=$(echo "$2" | rev | cut -d / -f2- | rev);
        fi;
        shift;
        shift;;
      *)
        print_help;;
    esac
  done
}
