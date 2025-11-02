# myrmidon-k3s
An experimental Kubernetes base cluster. This is a Myrmidon inspired K3s cluster, a fleet of tiny PCs working fiercely and loyally to provide their services. Like ants following their queen, these nodes form a small but powerful army.


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

Note: It is good practice to always inspect any scripts before running them!

Run the script
```shell
bash ubuntu-post-install-script.sh
```

The script will prompt for the repository name, github user, and the necessary tokens. When complete, the cluster will complete building.

#### Manual Steps:

Automation of this area is still in design/prototyping phase.

- Once the cluster is running and you are able to access the home-assistant UI, create your user, create a long-lived access token, and connect a supported RGB lamp. Update the clusterbulb deployment to target the RGB lamp via HA_LIGHT_ENTITY_ID.
- Generate a new clusterbulb-secrets.yaml file, set the ha-token, use the previously used github token, then encrypt the file and push to your repo.
```
apiVersion: v1
kind: Secret
metadata:
  name: clusterbulb-secrets
  namespace: clusterbulb-monitor
type: Opaque
stringData:
  ha-token: ""
  gh-token: ""
```
`sops --age=$AGE_PUBLIC --encrypt --encrypted-regex '^(data|stringData)$' --in-place clusterbulb-secrets.yaml`


---

# Applications
- kube-prometheus-stack (prometheus/grafana)
- ntfy
- home-assistant (with matter integration)
- [go-clusterbulb](https://github.com/clustershed/go-clusterbulb)

  

---

This is based on an older version of my personal homelab when i was building it.





