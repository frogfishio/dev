FROM ubuntu:18.04
ARG USERNAME=vscode
ARG USER_UID=1000
ARG USER_GID=$USER_UID

# Set to false to skip installing zsh and Oh My ZSH!
ARG INSTALL_ZSH="true"

# Location and expected SHA for common setup script - SHA generated on release
ARG COMMON_SCRIPT_SOURCE="https://raw.githubusercontent.com/microsoft/vscode-dev-containers/v0.117.1/script-library/common-debian.sh"
ARG COMMON_SCRIPT_SHA="7fb5c8120574bab581b436d8523a57fb6c1d4a47f3aa990a25fc63dbd9c81b5b"

# Avoid warnings by switching to noninteractive
ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get -y install wget gnupg software-properties-common 

RUN wget -qO - https://download.docker.com/linux/ubuntu/gpg | apt-key add -
RUN wget -qO - https://www.mongodb.org/static/pgp/server-4.2.asc | apt-key add -
RUN echo "deb [ arch=amd64 ] https://repo.mongodb.org/apt/ubuntu bionic/mongodb-org/4.2 multiverse" | tee /etc/apt/sources.list.d/mongodb-org-4.2.list
RUN wget -qO - https://deb.nodesource.com/setup_12.x | bash -
RUN add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
RUN apt-add-repository -y ppa:ansible/ansible

# Configure apt and install packages
RUN apt-get update \
    && apt-get -y install --no-install-recommends \
    apt-utils \ 
    dialog \
    wget \
    net-tools \
    iputils-ping \
    dnsutils \
    ca-certificates \
    curl \
    gnupg \
    gnupg-agent \
    jq \
    unzip \
    pwgen \
    redis \
    build-essential \
    apt-transport-https \
    ca-certificates \
    software-properties-common \
    python3-pip \
    python3-setuptools \
    nginx \
    ansible \
    nodejs \
    mongodb-org \
    # docker-ce \
    docker-ce-cli \
    # containerd.io \
    2>&1 \
    #
    # Verify git, common tools / libs installed, add/modify non-root user, optionally install zsh
    && wget -q -O /tmp/common-setup.sh $COMMON_SCRIPT_SOURCE \
    && if [ "$COMMON_SCRIPT_SHA" != "dev-mode" ]; then echo "$COMMON_SCRIPT_SHA /tmp/common-setup.sh" | sha256sum -c - ; fi \
    && /bin/bash /tmp/common-setup.sh "$INSTALL_ZSH" "$USERNAME" "$USER_UID" "$USER_GID" \
    && rm /tmp/common-setup.sh \
    #
    # Clean up
    && apt-get autoremove -y \
    && apt-get clean -y \
    && rm -rf /var/lib/apt/lists/*

RUN pip3 install awscli \
    && pip3 install jmespath

RUN wget https://releases.hashicorp.com/terraform/0.12.26/terraform_0.12.26_linux_amd64.zip -O /tmp/terraform.zip -o /dev/null \
    && wget https://releases.hashicorp.com/packer/1.5.6/packer_1.5.6_linux_amd64.zip -O /tmp/packer.zip -o /dev/null \
    && wget https://storage.googleapis.com/kubernetes-release/release/v1.17.6/bin/linux/amd64/kubectl -O /usr/local/bin/kubectl -o /dev/null \
    && wget https://get.helm.sh/helm-v3.2.1-linux-amd64.tar.gz -O /tmp/helm.tgz -o /dev/null \
    && wget https://dl.google.com/go/go1.14.4.linux-amd64.tar.gz -O /tmp/golang.tgz -o /dev/null \
    && curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs > /tmp/rustup.sh && chmod +x /tmp/rustup.sh
    # && wget https://static.rust-lang.org/dist/rust-1.43.1-x86_64-unknown-linux-gnu.tar.gz -O /tmp/rust.tgz

RUN chmod 755 /usr/local/bin/kubectl \
    && unzip /tmp/terraform.zip -d /usr/local/bin/ \
    && unzip /tmp/packer.zip -d /usr/local/bin/ \
    && tar zxf /tmp/helm.tgz -C /tmp && install /tmp/linux-amd64/helm /usr/local/bin \
    && tar zxf /tmp/golang.tgz -C /usr/local \
    && sum -c "/tmp/rustup.sh -y" vscode

RUN echo -e "\nexport PATH=\$PATH:/usr/local/go/bin" >> /etc/profile

# Install faas
RUN helm repo add stable https://kubernetes-charts.storage.googleapis.com/ \
    && curl -SLsf https://dl.get-arkade.dev/ | sudo sh \
    && curl -sL https://cli.openfaas.com | sh

# Install supplemental tools
RUN npm install -g gulp mocha typescript tsc-watch @angular/cli stylus nib

# Switch back to dialog for any ad-hoc use of apt-get
ENV DEBIAN_FRONTEND=dialog