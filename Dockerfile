## Android alpine base
ARG JDK_VERSION=21.0.1
FROM bellsoft/liberica-openjdk-alpine:${JDK_VERSION} as base
ARG CMDLINE_VERSION=11076708
ARG SDK_TOOLS_VERSION=11076708
ARG NDK=27.1.12297006
ARG CMAKE=3.22.1

ENV ANDROID_SDK_ROOT="/opt/sdk"
ENV ANDROID_HOME=${ANDROID_SDK_ROOT}
ENV NDK_HOME=${ANDROID_SDK_ROOT}/ndk/${NDK}
ENV PATH=$PATH:${ANDROID_SDK_ROOT}/cmdline-tools/${CMDLINE_VERSION}/bin:${ANDROID_SDK_ROOT}/platform-tools:${ANDROID_SDK_ROOT}/extras/google/instantapps

RUN apk upgrade && \
    apk add --no-cache bash curl git unzip musl-dev libgcc gcc wget coreutils openssh-client tar && \
    rm -rf /tmp/* && \
    rm -rf /var/cache/apk/* && \
    mkdir -p ${ANDROID_SDK_ROOT} && \
    busybox unzip <(wget -qO- https://dl.google.com/android/repository/commandlinetools-linux-${SDK_TOOLS_VERSION}_latest.zip) -qK -d ${ANDROID_SDK_ROOT}/cmdline-tools && \
    mv ${ANDROID_SDK_ROOT}/cmdline-tools/* ${ANDROID_SDK_ROOT}/cmdline-tools/${CMDLINE_VERSION} && \
    mkdir -p ~/.android/ && \
    touch ~/.android/repositories.cfg && \
    chmod +x ${ANDROID_SDK_ROOT}/cmdline-tools/${CMDLINE_VERSION}/bin/sdkmanager && \
    yes | sdkmanager --sdk_root=${ANDROID_SDK_ROOT} --licenses && \
    sdkmanager --sdk_root=${ANDROID_SDK_ROOT} --install "platform-tools" "extras;google;instantapps" && \
        sdkmanager --sdk_root=${ANDROID_SDK_ROOT} --install "ndk;${NDK}" && \
        sdkmanager --sdk_root=${ANDROID_SDK_ROOT} --install "cmake;${CMAKE}"

# install rust and setup android targets
FROM base as rust
RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs > rust.sh && \
        chmod +x ./rust.sh && \
        ./rust.sh -y && \
        rm ./rust.sh
ENV PATH=$PATH:/root/.cargo/bin
RUN rustup target add aarch64-linux-android armv7-linux-androideabi i686-linux-android x86_64-linux-android

# setup node and corepack
FROM rust as node
RUN curl -fsSL https://raw.githubusercontent.com/tj/n/master/bin/n | bash -s 22
RUN corepack enable

# optional
FROM node as bun
RUN curl -fsSL https://bun.sh/install > bun.sh && \
        chmod +x ./bun.sh && \
        ./bun.sh
ENV PATH=$PATH:/root/.bun/bin


CMD ["/bin/bash"]
