variable "hcloudToken" {
  type = string
  description = "API Token for Hetzner Cloud service"
  sensitive = true
}


source "hcloud" "jenkins-slave_de" {
  image = "ubuntu-22.04"
  ssh_username = "root"
  location = "nbg1"
  token = var.hcloudToken
  server_type = "cx11"
  snapshot_name = "jenkins-slave"
  snapshot_labels = {
    "jenkins": "agent_de"
  }
}

source "hcloud" "jenkins-slave_us" {
  image = "ubuntu-22.04"
  ssh_username = "root"
  location = "ash"
  token = var.hcloudToken
  server_type = "cpx11"
  snapshot_name = "jenkins-slave"
  snapshot_labels = {
    "jenkins": "agent_us"
  }
}


build {
  name = "jenkins-slave"
  sources = ["sources.hcloud.jenkins-slave_de", "sources.hcloud.jenkins-slave_us"]
  provisioner "shell" {
    inline = [
      "apt-get update",
      "DEBIAN_FRONTEND=noninteractive apt-get -y upgrade",
      "apt-get install -y openjdk-11-jre-headless",
      "curl https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor | sudo tee /etc/apt/keyrings/docker.gpg >/dev/null",
      "curl https://packages.cloud.google.com/apt/doc/apt-key.gpg -o /etc/apt/keyrings/kubernetes-archive-keyring.gpg",
      "echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-archive-keyring.gpg] https://apt.kubernetes.io/ kubernetes-xenial main' > /etc/apt/sources.list.d/kubernetes.list",
      "curl https://baltocdn.com/helm/signing.asc | gpg --dearmor | sudo tee /etc/apt/keyrings/helm.gpg >/dev/null",
      "echo 'deb [signed-by=/etc/apt/keyrings/helm.gpg] https://baltocdn.com/helm/stable/debian/ all main' > /etc/apt/sources.list.d/helm-stable-debian.list",
      "echo 'deb [signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu jammy stable' > /etc/apt/sources.list.d/docker.list",
      "DEBIAN_FRONTEND=noninteractive apt-get -y install wget apt-transport-https gnupg lsb-release",
      "wget -qO - https://aquasecurity.github.io/trivy-repo/deb/public.key | gpg --dearmor | sudo tee /etc/apt/keyrings/trivy.gpg > /dev/null",
      "echo 'deb [signed-by=/etc/apt/keyrings/trivy.gpg] https://aquasecurity.github.io/trivy-repo/deb jammy main' > /etc/apt/sources.list.d/trivy.list",
      "DEBIAN_FRONTEND=noninteractive apt-get update && DEBIAN_FRONTEND=noninteractive apt install -y unzip git openjdk-8-jre-headless docker-ce docker-ce-cli containerd.io docker-compose python3-pip trivy libgtk2.0-0 libgtk-3-0 libgbm-dev libnotify-dev libgconf-2-4 libnss3 libxss1 libasound2 libxtst6 xauth xvfb jq kubectl helm",
      "curl -o /tmp/chromedriver.zip https://chromedriver.storage.googleapis.com/109.0.5414.119/chromedriver_linux64.zip && unzip /tmp/chromedriver.zip && mv chromedriver /usr/bin",
      "DEBIAN_FRONTEND=noninteractive apt-get -y install fonts-liberation libatk-bridge2.0-0 libatk1.0-0 libatspi2.0-0 libcairo2 libgbm1 libgtk-4-1 libpango-1.0-0 libwayland-client0 libxcomposite1 libxdamage1 libxfixes3 libxkbcommon0 libxrandr2 xdg-utils libu2f-udev libvulkan1",
      "curl -o /tmp/chrome-stable_amd64.deb https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb && dpkg -i /tmp/chrome-stable_amd64.deb",
      "curl -L https://github.com/mozilla/sops/releases/download/v3.7.3/sops_3.7.3_amd64.deb -o /tmp/sops_3.7.3_amd64.deb && dpkg -i /tmp/sops_3.7.3_amd64.deb",
      "adduser  --disabled-password --gecos \"Herr Jenkins\" jenkins",
      "adduser jenkins sudo",
      "adduser jenkins docker",
      "mkdir /home/jenkins/.ssh",
      "touch /home/jenkins/.ssh/authorized_keys",
      "echo \"|1|nBtBRsGi18n42cHou+H76cC4SFk=|ZIj1IGjiyZI2QkpzH3oV/AImj8I= ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIC9fKEsaHhq+XBqY96QccQTPOM5W1BhPMZQNBXRFL2IM\" > /home/jenkins/.ssh/known_hosts",
      "chown -R jenkins:jenkins /home/jenkins/.ssh ",
      "chmod 700 /home/jenkins/.ssh ",
      "chmod 600 /home/jenkins/.ssh/authorized_keys ",
      "chmod 600 /home/jenkins/.ssh/known_hosts ",
      "mkdir -p /Jenkins",
      "chmod 755 /Jenkins",
      "chown jenkins:jenkins /Jenkins",
      "su - jenkins -c \"git config --global user.email jenkins@bermuda.de\"",
      "su - jenkins -c \"git config --global user.name Herr Jenkins\"",
      "su - jenkins -c \"helm plugin install https://github.com/jkroepke/helm-secrets\"",
      "su - jenkins -c \"helm plugin install https://github.com/chartmuseum/helm-push\"",
    ]
  }
}
