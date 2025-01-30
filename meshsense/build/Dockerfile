# Use a lightweight Python base image
FROM python:3.9-slim

# Install system dependencies
RUN apt-get update && apt-get -y upgrade && \
    apt-get install -y --no-install-recommends \
        bluez-tools \
        bluez-hcidump \
        libbluetooth-dev \
        git \
        gcc \
        python3-setuptools \
        python3-pip \
        python3-pydbus && \
    rm -rf /var/lib/apt/lists/*

# Clone and install pybluez from source
RUN git clone https://github.com/pybluez/pybluez.git /tmp/pybluez && \
    cd /tmp/pybluez && \
    python3 setup.py install && \
    rm -rf /tmp/pybluez

# Set the working directory in the container
WORKDIR /app

# Copy the application code into the container
#COPY . /app

# Install Python dependencies if there's a requirements file

RUN git clone https://github.com/jalupaja/BlueDucky.git .
RUN if [ -f requirements.txt ]; then pip install -r requirements.txt; fi

# Define the entrypoint
CMD ["python3", "BlueDucky.py"]
