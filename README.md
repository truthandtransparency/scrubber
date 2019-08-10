# Scrubber

A tool to "scrub" PDFs of metadata, fingerprints, watermarks, and other identifying data and optimize them for publication to the web.

Scrubber is a wrapper combining several other open source tools including [PDF Redact Tools](https://github.com/firstlookmedia/pdf-redact-tools), [OCRmyPDF](https://github.com/jbarlow83/OCRmyPDF), and [QPDF](https://github.com/qpdf/qpdf). It was originally written with the intent to protect whistleblowers submitting documents to the TTF.

Scrubber achieves this goal in the following steps:
1. Use `pdf-redact-tools` to convert each page of the PDF into an individual image and then combine them back to a single PDF.
 - This is in effort to remove any digital watermarks or fingerprints.
 - The user has the option to just produce images, redact them separately, and then merge later.
2. Make the PDF searchable by adding the text layer with `ocrmypdf`.
 - `ocrmypdf` also compresses the file size of the PDF.
3. Optimize the PDF to be hosted online by [linearizing](https://docs.oracle.com/cd/E51711_01/TSG/FAQ/What%20are%20linearized%20PDF%20files_.html) it with `qpdf`.
4. Remove any exif data created in the previous 3 steps using `exiftool`.

## PREREQUISITES:
You must have [Docker](https://www.docker.com/) installed. It can be installed on [CentOS](https://docs.docker.com/install/linux/docker-ce/centos/), [Debian](https://docs.docker.com/install/linux/docker-ce/debian/), [Fedora](https://docs.docker.com/install/linux/docker-ce/fedora/), [Ubunutu](https://docs.docker.com/install/linux/docker-ce/ubuntu/), [macOS](https://docs.docker.com/docker-for-mac/install/), and [Windows](https://docs.docker.com/docker-for-windows/install/).

## USAGE:
The easiest and most simple way to run Scrubber is by running the following command:
```
./scrubber.sh -i /path/to/input/pdf -o /path/to/desired/output/pdf
```
That will pull down the official Scrubber [docker container](https://hub.docker.com/r/truthandtransparency/scrubber) and work it's magic. If you'd rather not pull the container from Docker Hub and build is locally, you can run:
```
./scrubber.sh --local -i /path/to/input/pdf -o /path/to/desired/output/pdf
```

_*NOTE: Currently Scrubber requires that absolute filepaths be passed to it. This will be fixed in the near future._

A full list of command options is as follows:

```
Command:
[] = required parameters
<> = optional parameters

scrubber.sh <options> -i|--input [input_file_path] -o|--output [output_file_path] 

Options:
 --local: Build docker image locally rather than pulling form Docker Hub
 -l, --language <language>: Language for PDF OCR (https://github.com/tesseract-ocr/tesseract/blob/master/doc/tesseract.1.asc#languages)
 -a, --achromatic: Remove color from PDF to avoid Reality Winner's situation. Cannot be set with -m or --merge
 -r, --redact: Just separate the pages of the PDF into PNGs for redactions
 -m, --merge: Just merge the PNGs
 -h, --help: Print this help text
 -i, --input: PDF to scrub
 -o, --output: Filepath for clean PDF
```

## FILES
### Dockerfile
The file used to build the Docker image. More info can be read [here](https://docs.docker.com/develop/develop-images/dockerfile_best-practices/).

### scrub.sh
The bash script that actually does the 4 steps outlined above. This script is copied to the Docker container to `/usr/local/bin/scrub`.

### scrubber.sh
A bash wrapper around the appropriate docker commands.

### common_functions.sh
A bash script containing functions used in both `scrub.sh` and `scrubber.sh`.

 ## LICENSING
 Scrubber is licensed under the [GNU General Public License v3.0](LICENSE). 

 ## DISCLAIMER
 There is absolutely no guarantee that Scrubber will completely clean all potentially identifying information from a document. It should not be treated as a "silver bullet".

 ## ROADMAP
 - Account for relative file paths ([Issue #1](https://github.com/truthandtransparency/scrubber/issues/1))
 - Take spaces into account in filenames ([Issue #2](https://github.com/truthandtransparency/scrubber/issues/2))
 - Decrease Docker image size ([Issue #3](https://github.com/truthandtransparency/scrubber/issues/3))
 - Error handling ([Issue #4](https://github.com/truthandtransparency/scrubber/issues/4)
 - Unit testing ([Issue #5](https://github.com/truthandtransparency/scrubber/issues/5))
 - Include the option to scrub video files ([Issue #6](https://github.com/truthandtransparency/scrubber/issues/6))
