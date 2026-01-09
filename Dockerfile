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
    libffi-dev

# Install waterfurnace_aurora gem
RUN gem install --no-document waterfurnace_aurora

# Copy run script
COPY run.sh /
RUN chmod a+x /run.sh

CMD [ "/run.sh" ]
