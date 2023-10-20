ARG NCVERSION=26


FROM nextcloud:$NCVERSION AS recognize-git
################################################
###### Install Recognize

### install composer
## composer - same as above


#RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
#    --mount=type=cache,target=/var/lib/apt,sharing=locked \

RUN --mount=type=cache,target=/var/cache/apt \
    --mount=type=cache,target=/var/lib/apt \
    --mount=type=tmpfs,target=/tmp/ \
    --mount=type=tmpfs,target=/root/.cache \
    apt update && \
    apt install -y git

RUN --mount=type=tmpfs,target=/tmp/ \
    --mount=type=tmpfs,target=/root/.cache \
    mkdir -p /usr/src/nextcloud/custom_apps && cd /usr/src/nextcloud/custom_apps/ && \
    git clone https://github.com/nextcloud/recognize 
# Separate run, as sometimes removal was failing complaining dirs are not empty
RUN    rm -rf /usr/src/nextcloud/custom_apps/recognize/.git*/*



FROM nextcloud:$NCVERSION

ENV CONDA_PREFIX=/0_nondist/conda/
ENV PATH=$PATH:$CONDA_PREFIX/bin:/var/www/html/

ENV CUDNN_VERSION=8.2.1
ENV CUDA_VERSION=11.3
#ENV CUDNN_VERSION=8.7.0
#ENV CUDA_VERSION=11.8

# NodeJS version selection
ENV NODE_MAJOR=20

# give heads up the git installation as it doesn't need apt access for git pull
RUN mkdir -p /tmp/certs && cd /tmp/certs && \
    curl -O http://www.cacert.org/certs/root_X0F.crt -O http://www.cacert.org/certs/class3_x14E228.crt && \
    mv root_X0F.crt /usr/local/share/ca-certificates/cacert-root.crt && \
    mv class3_x14E228.crt /usr/local/share/ca-certificates/cacert-class3.crt && \
    update-ca-certificates

RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,target=/var/lib/apt,sharing=locked \
    --mount=type=tmpfs,target=/tmp/ \
    --mount=type=tmpfs,target=/root/.cache \
    --mount=type=tmpfs,target=/root/.npm \
    apt update && \
    apt install -y youtube-dl aria2 lsof coreutils wget gnupg2 git software-properties-common logrotate sudo && \
    echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_$NODE_MAJOR.x nodistro main" | tee /etc/apt/sources.list.d/nodesource.list && \
    curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key | gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg && \
    apt-key adv --fetch-keys https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key && \
    apt update && \
    apt install -y nodejs

######## TensoFlow install with Conda/Pip
### Conda install start - toolkit

RUN --mount=type=tmpfs,target=/tmp/ \
    --mount=type=tmpfs,target=/root/.cache \
    --mount=type=tmpfs,target=/root/.npm \
    curl https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh -o /tmp/Miniconda3-latest-Linux-x86_64.sh && \
      bash /tmp/Miniconda3-latest-Linux-x86_64.sh -b -p $CONDA_PREFIX && \
    echo "$CONDA_PREFIX/lib" | tee /etc/ld.so.conf.d/zz-conda.conf && \
    ldconfig
#ENV LD_LIBRARY_PATH=$LD_LIBRARY_PATH:$CONDA_PREFIX/lib
#ENV LD_LIBRARY_PATH=$CONDA_PREFIX/lib/:$LD_LIBRARY_PATH

RUN --mount=type=tmpfs,target=/tmp/ \
    --mount=type=tmpfs,target=/root/.cache \
    --mount=type=tmpfs,target=/root/.npm \
    conda install -c "nvidia/label/cuda-11.3.0" cuda-nvcc cudatoolkit=$CUDA_VERSION cudnn=$CUDNN_VERSION 
#    conda install -c conda-forge cudatoolkit=$CUDA_VERSION cudnn=$CUDNN_VERSION 

### Conda installed

### Tensorflow and TensorRT
# removed nvidia-cuda-nvcc-cu12  
#pip install --upgrade pip && \
RUN --mount=type=tmpfs,target=/tmp/ \
    --mount=type=tmpfs,target=/root/.cache \
    --mount=type=tmpfs,target=/root/.npm \
    curl https://bootstrap.pypa.io/get-pip.py -o get-pip.py && \
    python3 get-pip.py --break-system-packages && \
    pip install --break-system-packages --upgrade tensorflow
#    pip install --break-system-packages --upgrade nvidia-cudnn-cu12 nvidia-cublas-cu12

################################################
###### Install Recognize

#ENV LD_LIBRARY_PATH=""
### install composer
## composer - same as above
RUN --mount=type=tmpfs,target=/tmp/ \
    --mount=type=tmpfs,target=/root/.cache \
    --mount=type=tmpfs,target=/root/.npm \
      ldconfig && \
      echo $LD_LIBRARY_PATH > /dev/stderr && \
      curl -sS https://getcomposer.org/installer -o /tmp/composer-setup.php && \
      HASH=`curl -sS https://composer.github.io/installer.sig` && \
      CHECK=`php -r "if (hash_file('SHA384', '/tmp/composer-setup.php') === '$HASH') { echo 'Installer verified'; } else { echo 'Installer corrupt'; unlink('composer-setup.php'); } echo PHP_EOL;"` && \
      if [ "$CHECK" = "Installer verified" ]; then \
        php /tmp/composer-setup.php --install-dir=/usr/local/bin --filename=composer; \
      else \
        exit 1 ; \
      fi

### Grab Recognize
RUN mkdir -p /usr/src/nextcloud/custom_apps/recognize && chown www-data: /usr/src/nextcloud/custom_apps/recognize -R
USER www-data
COPY --from=recognize-git /usr/src/nextcloud/custom_apps/ /usr/src/nextcloud/custom_apps/
#     chown www-data: /usr/src/nextcloud/custom_apps/recognizecd && 
USER root
RUN chown www-data: /usr/src/nextcloud/custom_apps/recognize -R
USER www-data:www-data

#RUN --mount=type=tmpfs,target=/tmp/ \
#    --mount=type=tmpfs,target=/root/.cache \
#    --mount=type=tmpfs,target=/root/.npm \
#    cd /usr/src/nextcloud/custom_apps/recognize && \
#    ls -l /usr/src/nextcloud/custom_apps/ && \
#    make

#COPY nextcloud.logrotate /etc/logrotate.d/logrotate.conf


#USER root
# Recognize test
# nodejs /usr/src/nextcloud/custom_apps/recognize/test_gputensorflow.js; echo $?

### Check if all works
#RUN python3 -c "import tensorflow as tf; print(tf.reduce_sum(tf.random.normal([1000, 1000])))" && \
#      python3 -c "import tensorflow as tf; print(tf.config.list_physical_devices('GPU'))"
#RUN python3 -c "import tensorrt;print(tensorrt.__version__);assert tensorrt.Builder(tensorrt.Logger());import tensorflow as tf;print(tf.config.list_physical_devices('GPU'))"
