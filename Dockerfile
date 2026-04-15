# Stage 1: Clone repositories and assemble resources
FROM public.ecr.aws/docker/library/node:24.11.0-bullseye-slim AS resources-builder

RUN apt-get update -y && \
    apt-get install -y --no-install-recommends wget git ca-certificates && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /repositories

RUN git clone --depth 1 --branch master https://github.com/ProjectIgnis/CardScripts.git edopro-card-scripts && \
    git clone --depth 1 --branch master https://github.com/ProjectIgnis/BabelCDB.git edopro-card-databases && \
    git clone --depth 1 --branch master https://github.com/ProjectIgnis/LFLists edopro-banlists-ignis && \
    git clone --depth 1 --branch main https://github.com/termitaklk/lflist edopro-banlists-evolution && \
    git clone --depth 1 https://code.moenext.com/nanahira/ygopro-scripts ygopro-scripts && \
    git clone --depth 1 --branch master https://github.com/evolutionygo/pre-release-database-cdb ygopro-prereleases-cdb && \
    git clone --depth 1 --branch main https://github.com/evolutionygo/cards-art-server ygopro-cards-art && \
    git clone --depth 1 --branch main https://github.com/evolutionygo/server-formats-cdb.git ygopro-format-alternatives && \
    wget -O ygopro-lflist.conf https://cdntx.moecube.com/ygopro-database/zh-CN/lflist.conf && \
    wget -O ygopro-cards.cdb https://cdntx.moecube.com/ygopro-database/zh-CN/cards.cdb


# Stage 2: Build CoreIntegrator
FROM public.ecr.aws/docker/library/node:24.11.0-bullseye-slim AS core-builder

RUN apt-get update -y && \
    apt-get install -y --no-install-recommends \
    g++ make cmake pkg-config \
    libboost-system-dev \
    libsqlite3-dev \
    libjsoncpp-dev \
    nlohmann-json3-dev \
    libcurl4-openssl-dev && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Copy whole repo
COPY . .

# IMPORTANT FIX — ensure modules exist where compiler expects
RUN mkdir -p /app/core/modules && \
    if [ -d "/app/core/src/modules" ]; then \
        cp -r /app/core/src/modules/* /app/core/modules/; \
    fi

WORKDIR /app/core

RUN cmake -B build -S . -DCMAKE_BUILD_TYPE=Release && \
    cmake --build build -- -j1


# Stage 3: Build Node.js server
FROM public.ecr.aws/docker/library/node:24.11.0-bullseye AS server-builder

WORKDIR /server

COPY package.json package-lock.json ./
RUN npm ci

RUN git clone --depth 1 https://github.com/diangogav/evolution-types.git ./src/evolution-types

COPY . .

RUN npm run build && \
    npm prune --production


# Stage 4: Final image
FROM public.ecr.aws/docker/library/node:24.11.0-slim

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    curl \
    liblua5.3-dev \
    libsqlite3-dev \
    libevent-dev \
    dumb-init && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /app

COPY --from=server-builder /server/dist ./
COPY --from=server-builder /server/package.json ./package.json
COPY --from=server-builder /server/node_modules ./node_modules

COPY --from=core-builder /app/core/libocgcore.so ./core/libocgcore.so
COPY --from=core-builder /app/core/CoreIntegrator ./core/CoreIntegrator

COPY --from=resources-builder /resources ./resources

CMD ["dumb-init", "node", "./src/index.js"]
