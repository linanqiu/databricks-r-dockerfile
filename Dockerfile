FROM databricksruntime/minimal:latest

ENV DEBIAN_FRONTEND=noninteractive 

ENV R_CRAN_REPO=https://packagemanager.rstudio.com/all/__linux__/bionic/latest

# Ubuntu 16.04.3 LTS installs R version 3.2.3 by default. This is fairly out dated.
# We add RStudio's debian source to install the latest r-base version (3.6.0)
# We are using the more secure long form of pgp key ID of marutter@gmail.com
# based on these instructions (avoiding firewall issue for some users):
# https://cran.rstudio.com/bin/linux/ubuntu/#secure-apt
RUN apt-get update \
  && apt-get install --yes software-properties-common apt-transport-https \
  && gpg --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys E298A3A825C0D65DFD57CBB651716619E084DAB9 \
  && gpg -a --export E298A3A825C0D65DFD57CBB651716619E084DAB9 | sudo apt-key add - \
  && add-apt-repository 'deb [arch=amd64,i386] https://cran.rstudio.com/bin/linux/ubuntu bionic-cran40/' \
  && apt-get update \
  && apt-get install --yes \
    libssl-dev \
    r-base \
    r-base-dev \
    curl \
    libcurl4-openssl-dev \
    libxml2-dev \
    littler \
  && ln -s /usr/lib/R/site-library/littler/examples/install.r /usr/local/bin/install.r \
  && ln -s /usr/lib/R/site-library/littler/examples/install2.r /usr/local/bin/install2.r \
  && ln -s /usr/lib/R/site-library/littler/examples/installGithub.r /usr/local/bin/installGithub.r \
  && ln -s /usr/lib/R/site-library/littler/examples/testInstalled.r /usr/local/bin/testInstalled.r \
  && add-apt-repository -r 'deb [arch=amd64,i386] https://cran.rstudio.com/bin/linux/ubuntu bionic-cran40/' \
  && apt-key del E298A3A825C0D65DFD57CBB651716619E084DAB9 \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# # hwriterPlus is used by Databricks to display output in notebook cells
# # Rserve allows Spark to communicate with a local R process to run R code
# RUN R -e "install.packages(c('hwriterPlus'), repos='https://mran.revolutionanalytics.com/snapshot/2017-02-26')" \
#  && R -e "install.packages(c('htmltools'), repos='https://cran.microsoft.com/')" \
#  && R -e "install.packages('Rserve', repos='http://rforge.net/')"

# Additional instructions to setup rstudio. If you dont need rstudio, you can 
# omit the below commands in your docker file. Even after this you need to use
# an init script to start the RStudio daemon (See README.md for details.)

# Databricks configuration for RStudio sessions.
COPY Rprofile.site /usr/lib/R/etc/Rprofile.site

RUN echo "options(repos=c(CRAN='$R_CRAN_REPO'))" >> /usr/lib/R/etc/Rprofile.site \
  && R -e "install.packages(c('docopt', 'remotes'))"

RUN install2.r --error \
    tidyverse \
    htmltools \
    htmlwidgets \
    Rserve \
    BART \
    benchmarkme \
    shiny \
  && install2.r --error \
    --repos=https://mran.microsoft.com/snapshot/2017-02-26 hwriterPlus \
  && rm -rf /tmp/* /var/tmp/*

# Rstudio installation.
RUN apt-get update \
 # Installation of rstudio in databricks needs /usr/bin/python.
 && apt-get install -y python \
 # Install gdebi-core.
 && apt-get install -y gdebi-core \
 # Download rstudio 1.2 package for ubuntu 16.04 and install it.
 && apt-get install -y wget \
 && wget https://download2.rstudio.org/server/bionic/amd64/rstudio-server-1.4.1717-amd64.deb -O rstudio-server.deb \
 && gdebi -n rstudio-server.deb \
 && rm rstudio-server.deb