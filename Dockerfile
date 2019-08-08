# Base docker image
FROM ubuntu:18.04 
LABEL maintainer "Ethan Gregory Dodge <egd@truthandtransparency.org>"

# Install packages via apt
RUN apt update && apt install -y gnupg \
    && echo "deb http://ppa.launchpad.net/micahflee/ppa/ubuntu bionic main" | tee -a /etc/apt/sources.list.d/pdf-redact-tools.list \
    && echo "deb-src http://ppa.launchpad.net/micahflee/ppa/ubuntu bionic main" | tee -a /etc/apt/sources.list.d/pdf-redact-tools.list \
    && apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 7D158F33 \
    && apt update && apt install -y \
    pdf-redact-tools \
    ocrmypdf \
    $(apt-cache search tesseract-ocr | while read line ; do echo -n $line | cut -f 1 -d ' '; done) \
    git gcc \
    && rm -rf /var/lib/apt/lists/* 

# Build qpdf
RUN apt update && apt install -y \
    git gcc libjpeg-dev \
    zlib1g-dev build-essential \
    && git clone https://github.com/qpdf/qpdf.git /root/qpdf \
    && cd /root/qpdf \
    && /bin/sh /root/qpdf/configure \
    && make --directory /root/qpdf \
    && make install --directory /root/qpdf \
    && rm -rf /root/qpdf \
    && apt purge -y git gcc \
    libjpeg-dev zlib1g-dev build-essential \
    && apt autoremove -y

# Configure imagemagick to use more memory
RUN sed -i '/PDF/c\<policy domain=\"module\" rights=\"read|write\" pattern=\"{PDF}\" />' /etc/ImageMagick-*/policy.xml \
    && sed -i '/memory/c\<policy domain=\"resource\" name=\"memory\" value=\"4GiB\"/>' /etc/ImageMagick-*/policy.xml

ENV LC_ALL=C.UTF-8
ENV LANG=C.UTF-8

# Add scrubber user
RUN groupadd -r scrubber && useradd -r -g scrubber -G audio,video scrubber \
    && mkdir /home/scrubber && chown -R scrubber:scrubber /home/scrubber

# Add scrubber script
COPY scrub.sh /usr/local/bin/scrub
COPY common_functions.sh /home/scrubber/common_functions.sh
RUN chmod +x /usr/local/bin/scrub

# Run as non privileged user
USER scrubber

ENTRYPOINT [ "/usr/local/bin/scrub" ]
