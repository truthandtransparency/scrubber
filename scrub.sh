#!/usr/bin/env bash
#
### SCRUBBER ###
#          _____                   _____                   _____                   _____                   _____                   _____                   _____                   _____
#         /\    \                 /\    \                 /\    \                 /\    \                 /\    \                 /\    \                 /\    \                 /\    \
#        /::\    \               /::\    \               /::\    \               /::\____\               /::\    \               /::\    \               /::\    \               /::\    \
#       /::::\    \             /::::\    \             /::::\    \             /:::/    /              /::::\    \             /::::\    \             /::::\    \             /::::\    \
#      /::::::\    \           /::::::\    \           /::::::\    \           /:::/    /              /::::::\    \           /::::::\    \           /::::::\    \           /::::::\    \
#     /:::/\:::\    \         /:::/\:::\    \         /:::/\:::\    \         /:::/    /              /:::/\:::\    \         /:::/\:::\    \         /:::/\:::\    \         /:::/\:::\    \
#    /:::/__\:::\    \       /:::/  \:::\    \       /:::/__\:::\    \       /:::/    /              /:::/__\:::\    \       /:::/__\:::\    \       /:::/__\:::\    \       /:::/__\:::\    \
#    \:::\   \:::\    \     /:::/    \:::\    \     /::::\   \:::\    \     /:::/    /              /::::\   \:::\    \     /::::\   \:::\    \     /::::\   \:::\    \     /::::\   \:::\    \
#  ___\:::\   \:::\    \   /:::/    / \:::\    \   /::::::\   \:::\    \   /:::/    /      _____   /::::::\   \:::\    \   /::::::\   \:::\    \   /::::::\   \:::\    \   /::::::\   \:::\    \
# /\   \:::\   \:::\    \ /:::/    /   \:::\    \ /:::/\:::\   \:::\____\ /:::/____/      /\    \ /:::/\:::\   \:::\ ___\ /:::/\:::\   \:::\ ___\ /:::/\:::\   \:::\    \ /:::/\:::\   \:::\____\
#/::\   \:::\   \:::\____/:::/____/     \:::\____/:::/  \:::\   \:::|    |:::|    /      /::\____/:::/__\:::\   \:::|    /:::/__\:::\   \:::|    /:::/__\:::\   \:::\____/:::/  \:::\   \:::|    |
#\:::\   \:::\   \::/    \:::\    \      \::/    \::/   |::::\  /:::|____|:::|____\     /:::/    \:::\   \:::\  /:::|____\:::\   \:::\  /:::|____\:::\   \:::\   \::/    \::/   |::::\  /:::|____|
# \:::\   \:::\   \/____/ \:::\    \      \/____/ \/____|:::::\/:::/    / \:::\    \   /:::/    / \:::\   \:::\/:::/    / \:::\   \:::\/:::/    / \:::\   \:::\   \/____/ \/____|:::::\/:::/    /
#  \:::\   \:::\    \      \:::\    \                   |:::::::::/    /   \:::\    \ /:::/    /   \:::\   \::::::/    /   \:::\   \::::::/    /   \:::\   \:::\    \           |:::::::::/    /
#   \:::\   \:::\____\      \:::\    \                  |::|\::::/    /     \:::\    /:::/    /     \:::\   \::::/    /     \:::\   \::::/    /     \:::\   \:::\____\          |::|\::::/    /
#    \:::\  /:::/    /       \:::\    \                 |::| \::/____/       \:::\__/:::/    /       \:::\  /:::/    /       \:::\  /:::/    /       \:::\   \::/    /          |::| \::/____/
#     \:::\/:::/    /         \:::\    \                |::|  ~|              \::::::::/    /         \:::\/:::/    /         \:::\/:::/    /         \:::\   \/____/           |::|  ~|
#      \::::::/    /           \:::\    \               |::|   |               \::::::/    /           \::::::/    /           \::::::/    /           \:::\    \               |::|   |
#       \::::/    /             \:::\____\              \::|   |                \::::/    /             \::::/    /             \::::/    /             \:::\____\              \::|   |
#        \::/    /               \::/    /               \:|   |                 \::/____/               \::/____/               \::/____/               \::/    /               \:|   |
#         \/____/                 \/____/                 \|___|                  ~~                      ~~                      ~~                      \/____/                 \|___|          
#
# WRITTEN AND MAINTAINED BY THE TRUTH & TRANSPARENCY FOUNDATION (TTF)
# A NONPROFIT NEWSROOM DEDICATED TO PROMOTING TRANSPARENCY WITHIN RELIGIOUS INSTITUTIONS
# 
# Scrubber is meant for anyone who wants to scrub a PDF for any potenal trace of creator or source.
# It was originally written with the intent to protect whistleblowers submitting documents to the TTF.
#
# This script leverages several other open source tools to achieve its goal in the following steps:
# 1. Use `pdf-redact-tools` to convert the PDF into images and back to a PDF
#  - This is in effort to remove any digital watermarks or fingerprints
#  - The user has the option to just produce images, redact them separately, and then merge later
# 2. Make the PDF searchable by adding the text layer with `ocrmypdf`
#  - `ocrmypdf also compresses the file size of the PDF.
# 3. Optimize the PDF to be hosted online by linearizing it with `qpdf`
# 4. Remove any exif data created the previous 3 steps using `exiftool`
#
# Command:
# [] = required parameters
# <> = optional parameters
#
# scrub <options> -i|--input [input_file_path] -o|--output [output_file_path] 
#
# Options:
# -l, --language <language>: Language for PDF OCR (https://github.com/tesseract-ocr/tesseract/blob/master/doc/tesseract.1.asc#languages)
# -a, --achromatic: Remove color from PDF to avoid Reality Winner's situation. Cannot be set with -m or --merge
# -r, --redact: Just separate the pages of the PDF into PNGs for redactions
# -m, --merge: Just merge the PNGs
# -b, --batch: Batch mode. Provide directories of PDFs as --input and output to directory. Original will be renamed with *+original.pdf.
# -h, --help: Print this help text
# -i, --input: PDF to scrub
# -o, --output: Filepath for clean PDF

##### FUNCTIONS #####

# Check if file is PDF
function is_pdf(){
  type="$(file -b $1)"
  if [ "${type%%,*}" == "PDF document" ]; then
    return 0
  else
    return 1
  fi
}

### STEP 1 ###
## Use `pdf-redact-tools` to convert the PDF into images
function parse_redact(){

  # Produce the images to redact and merge later
  if [ "$2" -eq 1 ]; then
    # Should PDF be achromatic?
    if [ "$1" -eq 1 ]; then
      pdf-redact-tools --achromatic --explode "$4"
      exit 0
    else
      pdf-redact-tools --explode "$4"
      exit 0
    fi

  # Merge previously redacted images
  elif [ "$3" -eq 1 ]; then
    pdf-redact-tools --merge "$4"

  # No redactions, just sanitize the PDF
  else
    # Should PDF be achromatic?
    if [ "$1" -eq 1 ]; then
      pdf-redact-tools --achromatic --sanitize "$4"
    else
      pdf-redact-tools --sanitize "$4"
    fi
  fi
}

### STEP 2 ###
## Make the PDF searchable by adding the text layer with `ocrmypdf`.
function ocr(){
  ocrmypdf -l "$1" "$(echo $(dirname "$2")/$(basename "$2") | cut -f 1 -d .)-final.pdf" "$3"
}

### STEP 3 ###
## Optimize the PDF to be hosted online by linearizing it with `qpdf`
function linearize(){
  qpdf --linearize "$1" "$2"
}

### STEP 4 ###
## Remove any exif data created the previous 3 steps using exiftool
function exif(){
  exiftool -m -all:all= "$1"
}

# Clean stuff up
function clean_up(){
  rm -f "$(echo $(dirname "$1")/$(basename "$1") | cut -f 1 -d .)-final.pdf"
  rm -rf "$(echo $(dirname "$1")/$(basename "$1") | cut -f 1 -d .)_pages"
  rm -f "$2+to-linearize"
  rm -r "$2_original"
}

function batch_mode(){
  for file in $(ls "$1"); do
    if is_pdf "$1""$file"; then
      INPUT_FILE="$1""$(echo $file | cut -f 1 -d .)+original.pdf"
      mv "$1""$file" "$INPUT_FILE" 
      OUTPUT_FILE="$2""$file"
      do_the_shit
    # If the file isn't a PDF, move on to the next one.
    else
      print_message "INFO" "The file, $file, is not a PDF. Continuing to the next document."
      continue
    fi
  done
}

function do_the_shit(){
  # If the file isn't a PDF, exit.
  if [[ "$BATCH_MODE" -eq 0 ]] && ! is_pdf "$INPUT_FILE"; then
    print_message "ERROR" "The file, $INPUT_FILE, is not a PDF."
  fi

  print_message "INFO" "Running PDF Redact Tools:"
  parse_redact "$ACHROMATIC" "$REDACT" "$MERGE" "$INPUT_FILE"
  
  print_message "INFO" "Adding text layer with OCRmyPDF:"
  ocr "$LANGUAGE" "$INPUT_FILE" "$OUTPUT_FILE+to-linearize"

  print_message "INFO" "Optimizing for web publication by linearizing with QPDF:"
  linearize "$OUTPUT_FILE+to-linearize" "$OUTPUT_FILE"

  print_message "INFO" "Removing EXIF data:"
  exif "$OUTPUT_FILE"

  print_message "INFO" "Cleaning up shop."
  clean_up "$INPUT_FILE" "$OUTPUT_FILE" 

  print_message "INFO" "All done. Your final file is $(echo $OUTPUT_FILE | rev | cut -d / -f 1 | rev)"
}

##### DO THE SHIT #####

set -e

source /home/scrubber/common_functions.sh
parse_args "$@"

if [ "$BATCH_MODE" -eq 1 ]; then
  batch_mode "$INPUT_DIR" "$OUTPUT_DIR" 
else
  do_the_shit
fi
