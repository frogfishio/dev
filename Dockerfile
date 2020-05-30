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
# RUN wget -qO - https://www.mongodb.org/static/pgp/server-4.2.asc | apt-key add -
# RUN echo "deb [ arch=amd64 ] https://repo.mongodb.org/apt/ubuntu bionic/mongodb-org/4.2 multiverse" | tee /etc/apt/sources.list.d/mongodb-org-4.2.list
RUN wget -qO - https://deb.nodesource.com/setup_12.x | bash -
RUN add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"

# Configure apt and install packages
RUN apt-get update \
    && apt-get -y install --no-install-recommends \
    apt-utils \ 
    dialog \
    wget \
    ca-certificates \
    curl \
    gnupg \
    gnupg-agent \
    jq \
    unzip \
    pwgen \
    # redis \
    build-essential \
    apt-transport-https \
    ca-certificates \
    software-properties-common \
    python3-pip \
    python3-setuptools \
    nginx \
    ansible \
    nodejs \
    # mongodb-org \
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

RUN pip3 install awscli
RUN pip3 install jmespath
RUN curl -L https://storage.googleapis.com/kubernetes-release/release/v1.15.4/bin/linux/amd64/kubectl -o /usr/local/bin/kubectl
RUN chmod 755 /usr/local/bin/kubectl
RUN wget https://releases.hashicorp.com/terraform/0.12.7/terraform_0.12.7_linux_amd64.zip -O /tmp/terraform.zip -o /dev/null
RUN unzip /tmp/terraform.zip -d /usr/local/bin/

# Install supplemental tools
RUN npm install -g gulp mocha typescript tsc-watch @angular/cli stylus nib

# Switch back to dialog for any ad-hoc use of apt-get
ENV DEBIAN_FRONTEND=dialog