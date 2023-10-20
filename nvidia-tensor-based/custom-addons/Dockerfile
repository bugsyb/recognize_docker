ARG NCBASE="local/nextcloud:26.0.7-apache-tensor"

FROM $NCBASE AS recognize-git

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
# potentially add to docker-on-install/update copy/update


######################################################################################

FROM $NCBASE

ENV PATH=$PATH:/var/www/html/
# give heads up the git installation as it doesn't need apt access for git pull
RUN mkdir -p /tmp/certs && cd /tmp/certs && \
    curl -O http://www.cacert.org/certs/root_X0F.crt -O http://www.cacert.org/certs/class3_x14E228.crt && \
    mv root_X0F.crt /usr/local/share/ca-certificates/cacert-root.crt && \
    mv class3_x14E228.crt /usr/local/share/ca-certificates/cacert-class3.crt && \
    update-ca-certificates

COPY check-pip.sh /check-pip.sh
RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,target=/var/lib/apt,sharing=locked \
    --mount=type=tmpfs,target=/tmp/ \
    --mount=type=tmpfs,target=/root/.cache \
    --mount=type=tmpfs,target=/root/.npm \
    apt update && \
    apt install -y aria2 ffmpeg lsof coreutils wget logrotate sudo procps && \
    /check-pip.sh && \
    rm /check-pip.sh


#    apt install -y youtube-dl aria2 lsof coreutils wget gnupg2 git software-properties-common logrotate sudo && \

#COPY nextcloud.logrotate /etc/logrotate.d/logrotate.conf


#USER root
# Recognize test
# nodejs /usr/src/nextcloud/custom_apps/recognize/test_gputensorflow.js; echo $?

### Check if all works
#RUN python3 -c "import tensorflow as tf; print(tf.reduce_sum(tf.random.normal([1000, 1000])))" && \
#      python3 -c "import tensorflow as tf; print(tf.config.list_physical_devices('GPU'))"
#RUN python3 -c "import tensorrt;print(tensorrt.__version__);assert tensorrt.Builder(tensorrt.Logger());import tensorflow as tf;print(tf.config.list_physical_devices('GPU'))"
