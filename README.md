# myrmidon-k3s
An example Kubernetes base cluster. This is a Myrmidon inspired K3s cluster, a fleet of tiny PCs working fiercely and loyally to serve their master controller. Like ants following their queen, these nodes form a small but powerful army.


![The First k3s Myrmidon Soldier](https://raw.githubusercontent.com/clustershed/images/refs/heads/main/myrmidon-0-grafana-figure-and-hardware.jpg)


The quick start instructions are specific to this repository until the post-install script is expanded on for creating new.


# Quick Start

Requirements:
- A minimal installation of ubuntu 25 server with updates applied.
- A github access token for the repository owner.
  - Needed for flux-system installation and encrypted yaml.
- A github access token for the renovate bot.
  - Necessary for renovate to make pull requests for updates.
- Copy this repo to your own, and change necessary values.
  - The script is built for this repo specifically until expanded on to use/create a different repository.

Download the post-install script.
```shell
curl -s https://raw.githubusercontent.com/clustershed/myrmidon-k3s/refs/heads/main/ubuntu-post-install-script.sh > ubuntu-post-install-script.sh
```

Run the script
```shell
bash ubuntu-post-install-script.sh
```

The script will prompt for the repository name, github user, and the necessary tokens. Once complete, the cluster will complete building and will be ready to go.


---

This is based on an older version of my personal homelab when i was building it.





