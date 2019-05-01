FROM daocloud.io/ubuntu:16.04

ENV REFRESHED_AT 2019-05-02

COPY sources.list.16.04 /etc/apt/sources.list

RUN apt-get update

RUN apt-get install -y shadowsocks polipo
RUN apt-get install -y git wget curl man pkg-config zip g++ zlib1g-dev unzip apt-utils software-properties-common vim

RUN git config --global alias.st status
RUN git config --global alias.ci commit
RUN git config --global alias.co checkout

RUN apt-get install -y language-pack-zh-hans
RUN locale-gen zh_CN.UTF-8
RUN echo "export LC_ALL='zh_CN.utf8'" >> /root/.bashrc

RUN DEBIAN_FRONTEND=noninteractive apt-get install -yq tzdata
RUN ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime
RUN dpkg-reconfigure -f noninteractive tzdata

RUN curl -O https://nodejs.org/dist/v10.15.3/node-v10.15.3-linux-x64.tar.xz && \
      tar -xf node-v10.15.3-linux-x64.tar.xz && \
      mv node-v10.15.3-linux-x64 /usr/local/node && \
      rm node-v10.15.3-linux-x64.tar.xz
ENV PATH "$PATH:/usr/local/node/bin"

RUN npm install -g cnpm --registry=https://registry.npm.taobao.org
RUN npm config set registry https://registry.npm.taobao.org
RUN cnpm install -g truffle@5.0.0-beta.0
RUN cnpm install -g ganache-cli@6.1.8

COPY pip.conf /root/.pip/pip.conf

WORKDIR /this_project
