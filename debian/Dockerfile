# Build:
# DOCKER_BUILDKIT=1 docker build -t local/nextcloud-recognize-gpu .

ARG NCVERSION=26

FROM nextcloud:$NCVERSION AS recognize-git
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

RUN --mount=type=tmpfs,target=/tmp/ \
    --mount=type=tmpfs,target=/root/.cache \
    mkdir -p /usr/src/nextcloud/custom_apps && cd /usr/src/nextcloud/custom_apps/ && \
    git clone https://github.com/nextcloud/recognize 
# Separate run, as sometimes removal was failing complaining dirs are not empty
RUN    rm -rf /usr/src/nextcloud/custom_apps/recognize/.git*/*



FROM nextcloud:$NCVERSION

# CONDA unused  - apt/PIP used
#ENV CONDA_PREFIX=/0_nondist/conda/
#ENV PATH=$CONDA_PREFIX/bin:$PATH
#ENV LD_LIBRARY_PATH=$CONDA_PREFIX/lib/:$LD_LIBRARY_PATH

# choose version, depending on HW support
# https://docs.nvidia.com/deeplearning/cudnn/support-matrix/index.html
ENV CUDNN_VERSION=8.2.1
ENV CUDA_VERSION_NVIDIA=11-8

ENV LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/usr/local/cuda-11.8/lib64
ENV PATH=$PATH:/usr/local/cuda/bin

# NodeJS version selection
ENV NODE_MAJOR=20


###     curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key | gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg && \
##    apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys 2F59B5F99B1BE0B4 && \

# Notes
# software-properties-comon requried for nvidia
RUN  --mount=type=cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,target=/var/lib/apt,sharing=locked \
    --mount=type=tmpfs,target=/tmp/ \
    --mount=type=tmpfs,target=/root/.cache \
    apt update && \
    apt install -y youtube-dl aria2 lsof coreutils wget gnupg2 git software-properties-common logrotate sudo && \
    echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_$NODE_MAJOR.x nodistro main" | tee /etc/apt/sources.list.d/nodesource.list && \
    curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key | gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg && \
    apt-key adv --fetch-keys https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key && \
    apt update && \
    apt install -y nodejs

######## TensoFlow/pip install with Cuda/cudnn ia conda
### cuda & cudnn install start
# 2023.10.14 - no debian12 packages: debian12 => debian11 substition
RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,target=/var/lib/apt,sharing=locked \
    --mount=type=tmpfs,target=/tmp/ \
    --mount=type=tmpfs,target=/root/.cache \
    . /etc/os-release && \
    export OS="${ID}${VERSION_ID}" && \
 [ "$OS" = "debian12" ] && export OS=debian11 && \
    curl -fsSL https://nvidia.github.io/libnvidia-container/gpgkey | gpg --dearmor -o /usr/share/keyrings/nvidia-container-toolkit-keyring.gpg && \
      curl -s -L https://nvidia.github.io/libnvidia-container/stable/deb/nvidia-container-toolkit.list | \
        sed 's#deb https://#deb [signed-by=/usr/share/keyrings/nvidia-container-toolkit-keyring.gpg] https://#g' | \
          tee /etc/apt/sources.list.d/nvidia-container-toolkit.list && \
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

######## TensoFlow installed with Pip
RUN  --mount=type=cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,target=/var/lib/apt,sharing=locked \
    --mount=type=tmpfs,target=/tmp/ \
    --mount=type=tmpfs,target=/root/.cache \
    apt update && \
    apt -y install python3 python3-pip python3-setuptools python3-dev

### Tensorflow and TensorRT
# 2023.10.14 newer pip breaks tensorrt install at wheel time (download issue)
#    pip install --break-system-packages --upgrade pip && \
#   --use-pep517

RUN --mount=type=tmpfs,target=/tmp/ \
    --mount=type=tmpfs,target=/root/.cache \
    pip install --break-system-packages --upgrade pip==21.3.1 && \
    pip install --upgrade tensorflow tensorrt
#    pip install --break-system-packages --upgrade pip && \
#    pip install --break-system-packages --upgrade tensorflow tensorrt



################################################
###### Install Recognize

### install composer
## composer - same as above
RUN --mount=type=tmpfs,target=/tmp/ \
    --mount=type=tmpfs,target=/root/.cache \
    curl -sS https://getcomposer.org/installer -o /tmp/composer-setup.php && \
      HASH=`curl -sS https://composer.github.io/installer.sig` && \
      CHECK=`php -r "if (hash_file('SHA384', '/tmp/composer-setup.php') === '$HASH') { echo 'Installer verified'; } else { echo 'Installer corrupt'; unlink('composer-setup.php'); } echo PHP_EOL;"` && \
      if [ "$CHECK" = "Installer verified" ]; then \
        php /tmp/composer-setup.php --install-dir=/usr/local/bin --filename=composer; \
      else \
        exit 1 ; \
      fi

# give heads up the git installation as it doesn't need apt access for git pull
RUN mkdir -p /tmp/certs && cd /tmp/certs && \
    curl -O http://www.cacert.org/certs/root_X0F.crt -O http://www.cacert.org/certs/class3_x14E228.crt && \
    mv root_X0F.crt /usr/local/share/ca-certificates/cacert-root.crt && \
    mv class3_x14E228.crt /usr/local/share/ca-certificates/cacert-class3.crt && \
    update-ca-certificates
#RUN sleep 15


### Grab Recognize
RUN mkdir -p /usr/src/nextcloud/custom_apps/recognize && chown www-data: /usr/src/nextcloud/custom_apps/recognize -R
USER www-data
COPY --from=recognize-git /usr/src/nextcloud/custom_apps/ /usr/src/nextcloud/custom_apps/
#     chown www-data: /usr/src/nextcloud/custom_apps/recognizecd && 
USER root
RUN chown www-data: /usr/src/nextcloud/custom_apps/recognize -R
USER www-data:www-data

RUN --mount=type=tmpfs,target=/tmp/ \
    --mount=type=tmpfs,target=/root/.cache \
    cd /usr/src/nextcloud/custom_apps/recognize && \
    ls -l /usr/src/nextcloud/custom_apps/ && \
    make

COPY nextcloud.logrotate /etc/logrotate.d/logrotate.conf

#USER root
#### move to very early stage
#RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
#    --mount=type=cache,target=/var/lib/apt,sharing=locked \
#    --mount=type=tmpfs,target=/tmp/ \
#    --mount=type=tmpfs,target=/root/.cache \

# done
#    apt install -y sudo


# Recognize test
# nodejs /usr/src/nextcloud/custom_apps/recognize/test_gputensorflow.js; echo $?

### Check if all works
#RUN python3 -c "import tensorflow as tf; print(tf.reduce_sum(tf.random.normal([1000, 1000])))" && \
#      python3 -c "import tensorflow as tf; print(tf.config.list_physical_devices('GPU'))"
#RUN python3 -c "import tensorrt;print(tensorrt.__version__);assert tensorrt.Builder(tensorrt.Logger());import tensorflow as tf;print(tf.config.list_physical_devices('GPU'))"
