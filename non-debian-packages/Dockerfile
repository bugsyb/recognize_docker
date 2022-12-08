#unfinished - was for youtube-dl and aria2c ocdownloader
FROM nextcloud:25

ENV CONDA_PREFIX=/0_nondist/conda/
ENV PATH=$CONDA_PREFIX/bin:$PATH
ENV LD_LIBRARY_PATH=$CONDA_PREFIX/lib/:$LD_LIBRARY_PATH

ENV CUDNN_VERSION=8.2.1
ENV CUDA_VERSION=11.3
#ENV CUDNN_VERSION=8.7.0
#ENV CUDA_VERSION=11.8

RUN curl -fsSL https://deb.nodesource.com/setup_19.x | bash - && \
    apt install -y youtube-dl aria2 lsof coreutils wget gnupg2 git nodejs && \
    rm -rf /var/lib/apt/lists/* && \
    apt clean && \
    rm /tmp/* /root/.cache/* /root/.npm/* -rf

######## TensoFlow install with Conda/Pip
### Conda install start

RUN curl https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh -o /tmp/Miniconda3-latest-Linux-x86_64.sh && \
      bash /tmp/Miniconda3-latest-Linux-x86_64.sh -b -p $CONDA_PREFIX && \
      conda install -c conda-forge cudatoolkit=$CUDA_VERSION cudnn=$CUDNN_VERSION && \
    rm -rf /var/lib/apt/lists/* && \
    apt clean && \
    rm /tmp/* /root/.cache/* /root/.npm/* -rf

### Conda installed

### Tensorflow and TensorRT
RUN pip install --upgrade pip && \
       pip install tensorflow tensorrt && \
    rm -rf /var/lib/apt/lists/* && \
    apt clean && \
    rm /tmp/* /root/.cache/* /root/.npm/* -rf

######## TensoFlow installed with Conda/Pip
################################################
###### Install Recognize

### install composer
## composer - same as above
RUN curl -sS https://getcomposer.org/installer -o /tmp/composer-setup.php && \
      HASH=`curl -sS https://composer.github.io/installer.sig` && \
      CHECK=`php -r "if (hash_file('SHA384', '/tmp/composer-setup.php') === '$HASH') { echo 'Installer verified'; } else { echo 'Installer corrupt'; unlink('composer-setup.php'); } echo PHP_EOL;"` && \
      if [ "$CHECK" = "Installer verified" ]; then \
        php /tmp/composer-setup.php --install-dir=/usr/local/bin --filename=composer; \
      else \
        exit 1 ; \
      fi && \
    rm -rf /var/lib/apt/lists/* && \
    apt clean && \
    rm /tmp/* /root/.cache/* /root/.npm/* -rf

RUN mkdir -p /usr/src/nextcloud/custom_apps && cd /usr/src/nextcloud/custom_apps/ && \
    git clone https://github.com/nextcloud/recognize && \
    rm -rf /var/lib/apt/lists/* && \
    apt clean && \
    rm /tmp/* /root/.cache/* /root/.npm/* /usr/src/nextcloud/custom_apps/recognize/.git*/* -rf

RUN cd /usr/src/nextcloud/custom_apps/recognize && \
    make && \
    chown www-data: ../recognize -R

### Check if all works
#RUN python3 -c "import tensorflow as tf; print(tf.reduce_sum(tf.random.normal([1000, 1000])))" && \
#      python3 -c "import tensorflow as tf; print(tf.config.list_physical_devices('GPU'))"
#RUN python3 -c "import tensorrt;print(tensorrt.__version__);assert tensorrt.Builder(tensorrt.Logger());import tensorflow as tf;print(tf.config.list_physical_devices('GPU'))"

