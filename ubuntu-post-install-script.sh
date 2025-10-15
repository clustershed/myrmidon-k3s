#!/bin/bash

# curl -s https://raw.githubusercontent.com/clustershed/myrmidon-k3s/refs/heads/main/ubuntu-post-install-script.sh | bash

# exit immediately if any command returns a non-zero exit status
set -e


# ensure the script was not called with sudo
if [ -n "$SUDO_USER" ]; then
    echo "This script should not be run with sudo. Please run it as a regular user." >&2
    exit 1
fi


# check if an age.agekey file exists in the current directory
# if true, then this is a restore process with existing encryption keys
# if false we need to setup new encryption and necessary secrets
agekey_file_exists=false; [[ -f "/path/to/file" ]] && agekey_file_exists=true


# output to the cli so the user knows
if $agekey_file_exists; then
  echo "age.agekey file found. Using existing encryption."
else
  echo "age.agekey file not found. New encryption will be setup."
fi




# prompt the user for credentials and other necessary information
echo "Setup GitHub Connection:"
read -p "GITHUB_REPO=" ghRepo # k3s-aether
read -p "GITHUB_USER=" ghUser # clustershed
read -p "GITHUB_TOKEN=" ghToken
read -p "RENOVATE_TOKEN=" renToken



# confirm
echo ""
read -p "Do you want to proceed? Y/n: " yn
case $yn in
    [Yy]|[Yy][Ee][Ss])
        echo "Starting post installation ..."
        # Add your commands to execute if the user confirms here
        ;;
    [Nn]|[Nn][Oo])
        echo "Exiting..."
        exit 0
        ;;
    *)
        echo "Invalid input. Exiting..."
        exit 1
        ;;
esac


# script was confirmed, gather additional info
ipaddress=$(hostname -I | awk '{print $1}')
userName=$USER # save for later 


sudo swapoff -a # turn off swap
# and stop swap from re-enabling after reboot
# remove the swap entry from /etc/fstab
sudo sed -i '/swap/d' /etc/fstab


# enable IPv4 packet forwarding
# allows networking between pods across nodes
#cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
#net.ipv4.ip_forward = 1
#EOF
cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
net.ipv4.ip_forward = 1
EOF


sudo sysctl --system # apply sysctl without reboot


# install k3s without the helm controller, it will eb added later
curl -sfL https://get.k3s.io | sudo INSTALL_K3S_EXEC="--disable=helm-controller" sh


sleep 1 # let things settle a little


# copy the generated kubeconfig file locally
sudo cp /etc/rancher/k3s/k3s.yaml .


# set ownership
sudo chown $userName:$userName k3s.yaml

# place locally for this user
mkdir .kube
cp k3s.yaml .kube/config

# set the KUBECONFIG value
export KUBECONFIG=~/.kube/config

# make the KUBECONFIG value set on login
echo "export KUBECONFIG=~/.kube/config" >> ~/.bashrc

# set kubectl completion
source <(kubectl completion bash)

# copy the generated config to a local file with the repo name as the cluster name
# handle creation of secrets for apps and services if this is a new installation
cp k3s.yaml $GITHUB_REPO.yaml

# modify the new file so the ipaddress is changed from localhost to the external ip
sed -i "s/127.0.0.1/$ipaddress/g" $GITHUB_REPO.yaml

# add kubectl cli completion
echo "source <(kubectl completion bash)" >> .bashrc


# install flux, this will also handle helm
curl -s https://fluxcd.io/install.sh | sudo bash

# add flux cli completion
echo "source <(flux completion bash)" >> .bashrc


# refresh the current instance with the updated .bashrc file.
source ~/.bashrc



# install age
sudo apt install age


# Get the latest SOPS release tag from GitHub
latest_sops_version=$(curl -s https://api.github.com/repos/getsops/sops/releases/latest | grep -Po '"tag_name":\s*"\K.*?(?=")')

# Construct the download URL
url="https://github.com/getsops/sops/releases/download/${latest_version}/sops-${latest_sops_version}.linux.amd64"

echo "Downloading SOPS ${latest_sops_version} from ${url}..."

# Download the binary
#curl -Lo sops "${url}"
curl -Lo sops "https://github.com/getsops/sops/releases/download/v3.11.0/sops-v3.11.0.linux.amd64"

# Move the binary in to your PATH
sudo mv sops /usr/local/bin/sops

# Make the binary executable
sudo chmod +x /usr/local/bin/sops









# if the age.agekey file does not exist, generate it or error
#age-keygen -o age.agekey


if $agekey_file_exists; then
  echo "agekey exists ..."
else
  echo "Generating agekey ..."
  age-keygen -o age.agekey
fi


# get public key into var
export AGE_PUBLIC=$(awk -F': ' '/^# public key:/ {print $2}' age.agekey)
echo "echo \"AGE_PUBLIC=$AGE_PUBLIC\"" >> ~/.bashrc

sleep 3 # hold on a second or 3 for a look


# handle encryption of secrets for apps and services if this is a new installation
if $agekey_file_exists; then
  echo "keeping exiting encryptions ..."
else
  echo "Generating new encryptions ..."
  






  # using dry run, create the yaml for the renovate github token
  kubectl create secret generic renovate-container-env \
  --from-literal=RENOVATE_TOKEN=$renToken \
  --dry-run=client \
  -o yaml > renovate-container-env.yaml

  # encrypt the new yaml file in place
  sops --age=$AGE_PUBLIC --encrypt \
  --encrypted-regex '^(data|stringData)$' \
  --in-place renovate-container-env.yaml

  # move into the target location
  #mv renovate-container-env.yaml infrastructure/controllers/base/renovate/renovate-container-env.yaml 




  # setup a fun tls for grafana 
  # Generate the private key and certificate
  openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
    -keyout ./tls.key \
    -out ./tls.crt \
    -subj "/C=US/ST=Chicago/L=Shed/O=Home Lab Heroes Inc./OU=Department of Monitoring/CN=grafana.myrmidon-k3s" \
    -addext "subjectAltName=DNS:grafana.myrmdon-k3s"

  # generate the secret yaml with a dry run
  kubectl create secret tls grafana-tls-secret \
    --cert=tls.crt \
    --key=tls.key \
    --namespace=monitoring \
    --dry-run=client \
    -o yaml > grafana-tls-secret.yaml

  # encrypt it in place
  sops --age=$AGE_PUBLIC \
    --encrypt --encrypted-regex '^(data|stringData)$' \
    --in-place grafana-tls-secret.yaml

  # move into location
  #mv grafana-tls-secret.yaml monitoring/configs/staging/kube-prometheus-stack/grafana-tls-secret.yaml








fi



# export variables necessary for bootstrapping flux
export KUBECONFIG=~/.kube/config
export GITHUB_TOKEN=$ghToken
export GITHUB_USER=$ghUser


# run the flux bootstrap with the github repo as the source
flux bootstrap github \
  --owner=$ghUser \
  --repository=$ghRepo \
  --branch=main \
  --path=./clusters/staging \
  --personal

# create the sops-age secret for the cluster
cat age.agekey | kubectl create secret generic sops-age \
  --namespace=flux-system \
  --from-file=age.agekey=/dev/stdin





if $agekey_file_exists; then
  echo ""
else
  echo ""
  echo "New secrets were generated, the following files must be upated in the repository for re-installs using the generated age.agekey file."
  echo ""
  echo "infrastructure/controllers/base/renovate/renovate-container-env.yaml"
  echo "monitoring/configs/staging/kube-prometheus-stack/grafana-tls-secret.yaml"
  echo ""
  
fi






