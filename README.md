# recognize_docker
Recognize by marcelklehr (https://github.com/marcelklehr) put into Docker
Big kudos o to Marcel for comingup with such a nice piece of software as well as quickly reacting to an ask to add GPU support!

# Spee diff? ~ca. 25x (yes, 25 times quicker - average based on two systems testing):
- Intel© Xeon© CPU E3-1505M v6 @ 3.00GHz × 4, 32GB ram, Quadro M1200 Mobile (GM107GLM)
- Intel© Core© i7-4720HQ CPU @ 2.60GHz x 4, 16GB ram, GeForce GTX 960M (GM107M)
How was that measured? Single runs in average take similar amount of time (this could be completely wrong way of measuring it, though I can see and touch the difference without advanced metrics). Any suggestion on how to exactly measure it as well as tests output are more than welcome.

Dockers for Recognize with GPU support (git master branch based)
Two options available:
- Debian 11 + additional repo + pip - as close as possible to Debian based repos/binaries,
- Debian 11 + all rest added as additional items (MiniConda, Node, Pip).

In both cases resulting docker image is heavy due to Cuda/CudNN, Tensorflow/TensorRT and Recognize models included together with Nextcloud source.

Pre-reqs:
- nVidia GPU
- drivers enabled at host level (nvidia-smi required to work properly)
- docker with nvidia-toolkit enabled (to expose GPU to containers) - info can be found here: https://github.com/NVIDIA/nvidia-docker

If all is prepped well, this should work and provid nvidia-smi output from within container:
# sudo docker run --rm --gpus all nvidia/cuda:11.6.2-base-ubuntu20.04 nvidia-smi


How to use:
1. Build docker, i.e.:
cd <Dockerfile folder>
docker build -t local/nextcloud-recognize-gpu:latest .

2. Run it:
docker run -it --rm --gpus all <your usual mappings, i.e. volumes for NC data, etc> local/nextcloud-recognize-gpu:latest -d

In case of update, or moving existing data/deployment.
- Recognize with gpu support is in: /usr/src/nextcloud/custom_apps/recognize
- it needs to be:
#   rsync -avH /usr/src/nextcloud/custom_apps/recognize/ /var/www/html/custom_apps/recognize/
  
To validate if Recognize has any chances to use GPU, validate:
docker exec -it <your_container_name> /bin/bash -c "cd custom_apps/recognize && node ./src/test_gputensorflow.js"


# initial sizes 
- Debian base 20.8GB

