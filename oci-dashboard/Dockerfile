FROM debian:bullseye

RUN apt-get update && apt-get upgrade -y; \
    apt-get install -y \
    vim zsh curl wget git jq \
    && apt-get clean

# Install Oh My Zsh
RUN chsh -s $(which zsh); \
    wget https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh; \
    chmod +x install.sh && yes | ./install.sh; \
    rm install.sh

# Install OCI CLI
RUN wget https://raw.githubusercontent.com/oracle/oci-cli/master/scripts/install/install.sh; \
chmod +x ./install.sh && ./install.sh --accept-all-defaults

# Install Terraform
RUN apt-get update && apt-get -y install gnupg software-properties-common; \
wget -O- https://apt.releases.hashicorp.com/gpg | gpg --dearmor | tee /usr/share/keyrings/hashicorp-archive-keyring.gpg > /dev/null; \
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | tee /etc/apt/sources.list.d/hashicorp.list; \
apt-get update && apt-get -y install terraform

# Install kubectl
RUN curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"; \
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl.sha256"; \
echo "$(cat kubectl.sha256)  kubectl" | sha256sum --check; \
install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl

# RUN ssh-keygen -t rsa -b 2048 -f ~/.ssh/id_rsa -N "" -q

COPY ./resources /root/resources
WORKDIR /root/resources

COPY ./entrypoint.sh /root/entrypoint.sh
RUN chmod +x /root/entrypoint.sh

ENTRYPOINT ["bash", "/root/entrypoint.sh"]

CMD ["tail", "-f", "/dev/null"]