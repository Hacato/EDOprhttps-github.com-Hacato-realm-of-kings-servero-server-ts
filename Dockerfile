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
    git clone --depth 1 --branch main https://github.com/Hacato/Realm-Of-Kings.git realm-of-kings && \
    wget -O ygopro-lflist.conf https://cdntx.moecube.com/ygopro-database/zh-CN/lflist.conf && \
    wget -O ygopro-cards.cdb https://cdntx.moecube.com/ygopro-database/zh-CN/cards.cdb

RUN mkdir -p /resources

RUN mkdir -p \
    /resources/edopro/scripts \
    /resources/edopro/databases \
    /resources/edopro/banlists-ignis \
    /resources/edopro/banlists-evolution \
    /resources/ygopro/base/script \
    /resources/ygopro/prereleases-cdb \
    /resources/ygopro/cards-art \
    /resources/ygopro/cards-art/field \
    /resources/ygopro/alternatives \
    /resources/ygopro/ocg \
    /resources/realm-of-kings

RUN cp -r edopro-card-scripts/* /resources/edopro/scripts/ && \
    cp -r edopro-card-databases/* /resources/edopro/databases/ && \
    cp -r edopro-banlists-ignis/* /resources/edopro/banlists-ignis/ && \
    cp -r edopro-banlists-evolution/* /resources/edopro/banlists-evolution/ && \
    cp -r ygopro-scripts/* /resources/ygopro/base/script/ && \
    cp ygopro-lflist.conf /resources/ygopro/base/lflist.conf && \
    cp ygopro-cards.cdb /resources/ygopro/base/cards.cdb && \
    cp -r ygopro-prereleases-cdb/* /resources/ygopro/prereleases-cdb/ && \
    cp -r ygopro-cards-art/* /resources/ygopro/cards-art/ && \
    cp -r ygopro-format-alternatives/* /resources/ygopro/alternatives/ && \
    cp edopro-banlists-ignis/OCG.lflist.conf /resources/ygopro/ocg/lflist.conf && \
    find realm-of-kings -maxdepth 1 -name "*.cdb" -exec cp {} /resources/edopro/databases/ \; && \
    cp -r realm-of-kings/scripts/* /resources/edopro/scripts/ && \
    cp -r realm-of-kings/pics/* /resources/ygopro/cards-art/ && \
    cp -r realm-of-kings -T /resources/realm-of-kings

RUN test -d /resources || mkdir -p /resources


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

COPY . .

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

ENV HUSKY=0

RUN npm ci --ignore-scripts

RUN git clone --depth 1 https://github.com/diangogav/evolution-types.git ./src/evolution-types

COPY . .

RUN npm run build && \
    npm prune --production


# Stage 4: Final image
FROM public.ecr.aws/docker/library/node:24.11.0-bullseye

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    curl \
    liblua5.3-dev \
    libsqlite3-dev \
    libevent-dev \
    python3 \
    make \
    g++ \
    dumb-init && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /app

COPY --from=server-builder /server/dist ./dist
COPY --from=server-builder /server/package.json ./package.json
COPY --from=server-builder /server/node_modules ./node_modules

RUN npm rebuild better-sqlite3

COPY --from=core-builder /app/core/libocgcore.so ./core/libocgcore.so
COPY --from=core-builder /app/core/CoreIntegrator ./core/CoreIntegrator

COPY --from=resources-builder /resources ./resources

CMD ["dumb-init", "node", "./dist/src/index.js"]
