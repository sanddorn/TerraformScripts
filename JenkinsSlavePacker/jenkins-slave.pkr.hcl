variable "hcloudToken" {
  type = string
  description = "API Token for Hetzner Cloud service"
  sensitive = true
}

source "hcloud" "jenkins-slave" {
  image = "ubuntu-22.04"
  ssh_username = "root"
  location = "nbg1"
  token = var.hcloudToken
  server_type = "cx41"
  snapshot_name = "jenkins-slave"
  snapshot_labels = {
    "jenkins": "agent"
  }
}


build {
  name = "jenkins-slave"
  sources = ["sources.hcloud.jenkins-slave"]
  provisioner "shell" {
    inline = [
      "apt-get update",
      "apt-get -y upgrade",
      "apt-get install -y openjdk-11-jre-headless",
      "curl https://download.docker.com/linux/ubuntu/gpg | apt-key add -",
      "apt-add-repository 'deb https://download.docker.com/linux/ubuntu focal stable'",
      "apt-get -y install wget apt-transport-https gnupg lsb-release",
      "wget -qO - https://aquasecurity.github.io/trivy-repo/deb/public.key | gpg --dearmor | sudo tee /usr/share/keyrings/trivy.gpg > /dev/null",
      "echo \"deb [signed-by=/usr/share/keyrings/trivy.gpg] https://aquasecurity.github.io/trivy-repo/deb $(lsb_release -sc) main\" | sudo tee -a /etc/apt/sources.list.d/trivy.list",
      "apt-add-repository 'https://aquasecurity.github.io/trivy-repo/deb focal main'",
      "apt-get update && apt install -y unzip git openjdk-8-jre-headless docker-ce docker-ce-cli containerd.io docker-compose python3-pip trivy libgtk2.0-0 libgtk-3-0 libgbm-dev libnotify-dev libgconf-2-4 libnss3 libxss1 libasound2 libxtst6 xauth xvfb jq",
      "curl -o chromedriver.zip https://chromedriver.storage.googleapis.com/107.0.5304.62/chromedriver_linux64.zip && unzip chromedriver.zip && mv chromedriver /usr/bin",
      "apt-get -y install fonts-liberation libatk-bridge2.0-0 libatk1.0-0 libatspi2.0-0 libcairo2 libgbm1 libgtk-4-1 libpango-1.0-0 libwayland-client0 libxcomposite1 libxdamage1 libxfixes3 libxkbcommon0 libxrandr2 xdg-utils",
      "curl -o chrome-stable_amd64.deb https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb && dpkg -i chrome-stable_amd64.deb",
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
    ]
  }
}
