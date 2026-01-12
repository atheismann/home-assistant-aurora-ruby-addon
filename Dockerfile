# Build arguments (BUILD_FROM is provided by Home Assistant build system)
ARG BUILD_FROM=alpine:3.19
FROM ${BUILD_FROM}

# Set shell
SHELL ["/bin/bash", "-o", "pipefail", "-c"]

# Install Ruby and dependencies
RUN apk add --no-cache \
    ruby \
    ruby-dev \
    ruby-bundler \
    build-base \
    linux-headers \
    git \
    bash \
    jq \
    tzdata \
    libffi-dev \
    coreutils \
    tcpdump \
    strace \
    netcat-openbsd

# Install waterfurnace_aurora gem
RUN gem install --no-document waterfurnace_aurora

# Copy run script
COPY run.sh /
RUN chmod a+x /run.sh

# Health check using internal watchdog endpoint
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=10 \
  CMD nc -z localhost 8099 || exit 1

CMD [ "/run.sh" ]
