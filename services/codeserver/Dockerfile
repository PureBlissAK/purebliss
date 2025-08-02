FROM codercom/code-server:4.20.0

USER root

# Install Python3 and pip, then install hvac
RUN apt-get update && \
    apt-get install -y python3 python3-pip && \
    pip3 install --break-system-packages hvac && \
    rm -rf /var/lib/apt/lists/*

USER coder
