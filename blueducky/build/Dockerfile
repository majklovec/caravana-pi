FROM node
RUN apt-get update && apt-get install -y \
    build-essential \
    cmake \
    git \
    libbluetooth-dev \
    pkg-config \
    libdbus-1-3 \
    && rm -rf /var/lib/apt/lists/*

RUN npm install -g npm

WORKDIR /app

RUN git clone https://github.com/Affirmatech/MeshSense.git .

RUN /bin/sh -c ./update.mjs

EXPOSE 5920

CMD ["node", "index.cjs"]
