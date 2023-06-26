#!/bin/bash

# Original: https://gist.github.com/ctjlewis/7540d88f4ddb93d36e7515fb1b911833
# 
# This script is used to set up Python 3.9 + CUDA-enabled PyTorch on a Lambda
# Labs VM, along with specific dependencies for the Axolotl project.
# 
# It performs the following tasks:
#
# 1. Installs Python 3.9 and configures it as the default Python interpreter.
# 2. Installs pip, the Python package installer.
# 3. Configures Jupyter to use Python 3.9 by setting up ipykernel.
# 4. Removes system versions of PyTorch and torchvision to allow usage of
#    CUDA-enabled versions installed via pip.
# 5. Installs CUDA-enabled versions of PyTorch, torchvision, and torchaudio via
#    pip.
# 6. Sets the necessary library paths for running CUDA-enabled applications.
# 7. At the very end, it installs specific dependencies for the Axolotl project.
#
# Upon completion, Python 3.9 and CUDA-enabled PyTorch are ready for use in the
# Jupyter environment, and the Axolotl project is set up and ready for
# development.

log() {
    if [ -t 1 ]; then
        echo -e "\n\e[1m$1\e[0m"
    else
        echo -e "\n$1"
    fi
}

abort() {
    log "An error occurred. Exiting..."
    exit 1
}

trap 'abort' 0

log "Lambda Labs setup: Initiating installation of Python 3.9 and PyTorch with CUDA support..."

log "Starting Python 3.9 installation. Please select Python 3.9 from the alternatives config prompt when it appears..."
sudo apt update && sudo apt install -y python3.9
sudo update-alternatives --install /usr/bin/python python /usr/bin/python3.9 1
sudo update-alternatives --config python

version=$(python -V 2>&1 | grep -Po '(?<=Python )(.+)')
if [[ "${version:0:3}" < "3.9" ]]
then
    log "Failed to detect Python version >=3.9. Exiting..."
    exit 1
fi
log "Python version $version installed successfully."

log "Installing pip..."
wget https://bootstrap.pypa.io/get-pip.py
python get-pip.py && rm get-pip.py

log "Setting up Jupyter kernel for Python 3.9..."
python -m pip install --upgrade --force-reinstall pyzmq ipykernel
python -m ipykernel install --user

log "Setting LD Library path..."
export LD_LIBRARY_PATH=/usr/lib/x86_64-linux-gnu:$LD_LIBRARY_PATH

log "Uninstalling system versions of PyTorch to install CUDA-enabled versions via Pip..."
sudo apt-get remove -y python3-torch-cuda python3-torchvision-cuda

log "Force reinstalling CUDA-enabled PyTorch packages via Pip..."
pip3 install --upgrade --force-reinstall torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu118

log "Force reinstalling TensorFlow and its dependencies..."
pip3 install --upgrade --force-reinstall tensorflow pywrap tensorrt bitsandbytes

log "Installing Axolotl and its dependencies..."
pip3 install --upgrade --force-reinstall -e .
pip3 install --upgrade --force-reinstall protobuf==3.20.3 -U requests scipy --ignore-installed psutil git+https://github.com/huggingface/peft.git

trap : 0

log "Setup complete! Python 3.9, CUDA-enabled PyTorch, and the Axolotl project are now ready for use in the Jupyter environment."
