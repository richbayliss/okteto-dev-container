FROM ubuntu:20.04 AS base

ENV DEBIAN_FRONTEND=noninteractive
RUN rm -f ~/.bashrc && \
    touch ~/.bashrc

SHELL ["/bin/bash", "-c", "-l"]

# install utils
RUN apt-get update && \
    apt-get install -y curl && \
    apt-get autoremove -y && \
    apt-get clean -y && \
    rm -rf /var/lib/apt/lists/*

FROM base AS rust

# install rustup
RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- --profile=minimal -y
RUN rustup install stable && \
    rustup default stable

FROM base as node

# install nodejs
RUN curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.1/install.sh | bash
RUN cat ~/.bashrc && \
    nvm install 14 && \
    nvm use 14

# ---
FROM base AS staging

WORKDIR /build

# merge toolchains
COPY --from=rust /root rust
COPY --from=node /root node

# add bashrc header
COPY bashrc bashrc

# merge profiles
RUN cat rust/.bashrc node/.bashrc bashrc > .bashrc

FROM base

# merge toolchains
COPY --from=rust /root /root
COPY --from=node /root /root
COPY --from=staging /build/.bashrc /root/.bashrc

WORKDIR /usr/src/app
CMD [ "bash" ]
