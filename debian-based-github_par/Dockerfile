#unfinished - was for youtube-dl and aria2c ocdownloader

FROM nextcloud:25 AS recognize-git
################################################
###### Install Recognize

### install composer
## composer - same as above
RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,target=/var/lib/apt,sharing=locked \
    --mount=type=tmpfs,target=/tmp/ \
    --mount=type=tmpfs,target=/root/.cache \
    apt update && \
    apt install -y git
#      fi && \
#      rm /tmp/* /root/.cache/* -rf


RUN --mount=type=tmpfs,target=/tmp/ \
    --mount=type=tmpfs,target=/root/.cache \
    mkdir -p /usr/src/nextcloud/custom_apps && cd /usr/src/nextcloud/custom_apps/ && \
    git clone https://github.com/nextcloud/recognize && \
    rm /usr/src/nextcloud/custom_apps/recognize/.git*/* -rf


FROM nextcloud:25

ENV CONDA_PREFIX=/0_nondist/conda/
ENV PATH=$CONDA_PREFIX/bin:$PATH
ENV LD_LIBRARY_PATH=$CONDA_PREFIX/lib/:$LD_LIBRARY_PATH

ENV CUDNN_VERSION=8.2.1
ENV CUDA_VERSION=11.3
ENV CUDA_VERSION_NVIDIA=11-8
#ENV CUDNN_VERSION_NVIDIA=
#ENV CUDNN_VERSION=8.7.0
#ENV CUDA_VERSION=11.8

# Notes
# software-properties-comon requried for nvidia
RUN sleep 10

RUN  --mount=type=cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,target=/var/lib/apt,sharing=locked \
    --mount=type=tmpfs,target=/tmp/ \
    --mount=type=tmpfs,target=/root/.cache \
    curl -fsSL https://deb.nodesource.com/setup_19.x | bash - && \
    apt install -y youtube-dl aria2 lsof coreutils wget gnupg2 git nodejs software-properties-common
#    rm -rf /var/lib/apt/lists/* && \
#    apt clean && \
#    rm /tmp/* /root/.cache/* -rf


######## TensoFlow/pip install with Cuda/cudnn ia conda
### cuda & cudnn install start

RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,target=/var/lib/apt,sharing=locked \
    --mount=type=tmpfs,target=/tmp/ \
    --mount=type=tmpfs,target=/root/.cache \
    . /etc/os-release && \
    export OS="${ID}${VERSION_ID}" && \
    apt-key adv --fetch-keys https://developer.download.nvidia.com/compute/cuda/repos/${OS}/x86_64/3bf863cc.pub && \
    add-apt-repository "deb https://developer.download.nvidia.com/compute/cuda/repos/${OS}/x86_64/ /" && \
    apt update

RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,target=/var/lib/apt,sharing=locked \
    --mount=type=tmpfs,target=/tmp/ \
    --mount=type=tmpfs,target=/root/.cache \
    apt -y install --download-only cuda-toolkit-${CUDA_VERSION_NVIDIA} libcudnn8-dev


RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,target=/var/lib/apt,sharing=locked \
    --mount=type=tmpfs,target=/tmp/ \
    --mount=type=tmpfs,target=/root/.cache \
    apt -y install cuda-toolkit-${CUDA_VERSION_NVIDIA} libcudnn8-dev
#    rm -rf /var/lib/apt/lists/* && \
#    apt clean && \
#    rm /tmp/* /root/.cache/* -rf

RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,target=/var/lib/apt,sharing=locked \
    --mount=type=tmpfs,target=/tmp/ \
    --mount=type=tmpfs,target=/root/.cache \
    apt -y install python3-pip
#    rm -rf /var/lib/apt/lists/* && \
#    apt clean && \
#    rm /tmp/* /root/.cache/* -rf

### Tensorflow and TensorRT
RUN --mount=type=tmpfs,target=/tmp/ \
    --mount=type=tmpfs,target=/root/.cache \
    pip install --upgrade pip && \
    pip install tensorflow tensorrt
#    pip install tensorflow tensorrt && \
#    rm /tmp/* /root/.cache/* -rf


######## TensoFlow installed with Conda/Pip

### Grab Recognize
COPY --from=recognize-git /usr/src/nextcloud/custom_apps/ /usr/src/nextcloud/custom_apps/

RUN --mount=type=tmpfs,target=/tmp/ \
    --mount=type=tmpfs,target=/root/.cache \
    curl -sS https://getcomposer.org/installer -o /tmp/composer-setup.php && \
      HASH=`curl -sS https://composer.github.io/installer.sig` && \
      CHECK=`php -r "if (hash_file('SHA384', '/tmp/composer-setup.php') === '$HASH') { echo 'Installer verified'; } else { echo 'Installer corrupt'; unlink('composer-setup.php'); } echo PHP_EOL;"` && \
      if [ "$CHECK" = "Installer verified" ]; then \
        php /tmp/composer-setup.php --install-dir=/usr/local/bin --filename=composer; \
      else \
        exit 1 ; \
      fi && \
    cd /usr/src/nextcloud/custom_apps/recognize && \
    make && \
    chown www-data: ../recognize -R
#    chown www-data: ../recognize -R && \
#    rm /tmp/* /root/.cache/* -rf


RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,target=/var/lib/apt,sharing=locked \
    rm -rf /var/lib/apt/lists/* && \
    apt clean


### Check if all works
#RUN python3 -c "import tensorflow as tf; print(tf.reduce_sum(tf.random.normal([1000, 1000])))" && \
#      python3 -c "import tensorflow as tf; print(tf.config.list_physical_devices('GPU'))"
#RUN python3 -c "import tensorrt;print(tensorrt.__version__);assert tensorrt.Builder(tensorrt.Logger());import tensorflow as tf;print(tf.config.list_physical_devices('GPU'))"
