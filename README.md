# recognize_docker
Recognize by marcelklehr (https://github.com/marcelklehr) put into Docker
Big kudos o to Marcel for comingup with such a nice piece of software as well as quickly reacting to an ask to add GPU support!

Speed diff? ~ca. 25x (yes, 25 times quicker - average based on two systems testing):
- Intel© Xeon© CPU E3-1505M v6 @ 3.00GHz × 4, 32GB ram, Quadro M1200 Mobile (GM107GLM)
- Intel© Core© i7-4720HQ CPU @ 2.60GHz x 4, 16GB ram, GeForce GTX 960M (GM107M)
How was that measured? Single runs in average take similar amount of time (this could be completely wrong way of measuring it, though I can see and touch the difference without advanced metrics). Any suggestion on how to exactly measure it as well as tests output are more than welcome.

Dockers for Recognize with GPU support (git master branch based)
Three options available:
- Debian 12 + additional repo + pip - as close as possible to Debian based repos/binaries,
- Debian 12 + all rest added as additional items (MiniConda, Node, Pip).
- nVIDIA TensorFlow Docker image based (nvcr.io/nvidia/tensorflow:22.03-tf2-py3 as of 2023.10.20)

In all cases resulting docker image is heavy due to Cuda/CudNN, Tensorflow/TensorRT and Recognize models included together with Nextcloud source.

Pre-reqs:
- nVIDIA GPU
- drivers enabled at host level (nvidia-smi required to work properly)
- docker with nvidia-toolkit enabled (to expose GPU to containers) - info can be found here: https://github.com/NVIDIA/nvidia-docker

If all is prepped well, this should work and provid nvidia-smi output from within container:
`sudo docker run --rm --gpus all nvidia/cuda:11.6.2-base-ubuntu20.04 nvidia-smi`

Interestingly the Debian 12 based images come out smaller. Potentially I've missed some of other elements included within nVIDIA one though all works.


How to use:
1. Build docker, i.e.:
`cd <Dockerfile folder>
DOCKER_BUILDKIT=1 docker build -t local/nextcloud-recognize-gpu:latest .`

2. Run it:
`docker run -it --rm --gpus all <your usual mappings, i.e. volumes for NC data, etc> local/nextcloud-recognize-gpu:latest -d`

In case of update, or moving existing data/deployment.
- Recognize with gpu support is in: /usr/src/nextcloud/custom_apps/recognize
- it needs to be:
`   rsync -avH /usr/src/nextcloud/custom_apps/recognize/ /var/www/html/custom_apps/recognize/`
  
To validate if Recognize has any chances to use GPU, validate:
docker exec -it <your_container_name> /bin/bash -c "cd custom_apps/recognize && node ./src/test_gputensorflow.js"


initial sizes 
- 20.8GB - debian - Debian base
- 17.3GB - non-debian-packages - Debian + binary packages

Diff seems to be coming from the fact that Debian installs additional packages on the way.


Potential issues:
1. Default docker image size is 10GB, with latest cuda libraries it surprassses this size. To change image size 
- update configuration in 
`/etc/docker/daemon.json`:
`{
  "storage-opts": [
    "dm.basesize=20G"
  ]
}
`
- restart docker
- potentially remove cached images (or rebuild without cache)
`docker builder prune`


Known issue(s):
- Recognize run via cron coplaints about missing PTXAS in paths, though and relies on library known one - all works (by the looks of it), just complaint. This doesn't pop-up when run from CLI. Tried to set paths for cron, but didn't get it fixed as got attention on nVIDIA TensorFlow based one.
