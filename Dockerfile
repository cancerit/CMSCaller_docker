FROM rocker/r-ubuntu:20.04

USER root

ENV LC_ALL C
ENV LC_ALL C.UTF-8
ENV LANG C.UTF-8
ENV DISPLAY=:0
ENV DEBIAN_FRONTEND=noninteractive

ENV OPT /opt/wsi-t215
ENV R_LIBS $OPT/R-lib
ENV R_LIBS_USER $R_LIBS
ENV BUILD /build

# hadolint ignore=DL3059
RUN mkdir -p $R_LIBS_USER $BUILD
# hadolint ignore=DL3008
RUN apt-get update && \
  apt-get install -yq --no-install-recommends \
  libssl-dev \
  libcurl4-openssl-dev \
  libxml2-dev \
  libnlopt-dev \
  libbz2-dev \
  liblzma-dev \
  python3  \
  python3-dev \
  python3-setuptools \
  python3-pip \
  python3-wheel \
  unattended-upgrades && \
  unattended-upgrade -d -v && \
  apt-get remove -yq unattended-upgrades && \
  apt-get autoremove -yq \
  pandoc \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/*

COPY . $BUILD/
WORKDIR $BUILD

ENV INST_NCPU=$(nproc)

# hadolint ignore=DL3059
RUN R -e "install.packages('pkgdown', dependencies = TRUE, lib = Sys.getenv(\"R_LIBS_USER\"), Ncpus = Sys.getenv(\"INST_NCPU\"))"
RUN R -e "install.packages(c('remotes','BiocManager'), dependencies = TRUE, lib = Sys.getenv(\"R_LIBS_USER\"), Ncpus = Sys.getenv(\"INST_NCPU\"))"
# hadolint ignore=DL3059
RUN R -e "install.packages('https://cran.r-project.org/src/contrib/Archive/randomForest/randomForest_4.6-14.tar.gz', repos=NULL, type='source', lib = Sys.getenv(\"R_LIBS_USER\"), threads = Sys.getenv(\"INST_NCPU\"))"
RUN R -e "BiocManager::install(c('Biobase', 'limma','DNAcopy','pROC','PRROC','graphics'), lib = Sys.getenv(\"R_LIBS_USER\"), threads = Sys.getenv(\"INST_NCPU\"))"
RUN R -e "remotes::install_github('Lothelab/CMScaller')"
RUN R -e "remotes::install_github('francescojm/CRISPRcleanR')"
# python istallation
COPY requirements.txt $OPT/requirements.txt
RUN pip3 --no-cache-dir install -r $OPT/requirements.txt
RUN pip3 install https://sourceforge.net/projects/mageck/files/0.5/mageck-0.5.9.4.tar.gz
# hadolint ignore=DL3059

## user config
# hadolint ignore=DL3059
RUN adduser --disabled-password --gecos '' ubuntu && chsh -s /bin/bash && mkdir -p /home/ubuntu
WORKDIR /home/ubuntu
USER ubuntu

CMD ["/bin/bash"]
