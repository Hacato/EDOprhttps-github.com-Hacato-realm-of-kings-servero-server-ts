# Stage 1: Clone repositories and assemble resources
FROM public.ecr.aws/docker/library/node:24.11.0-bullseye-slim AS resources-builder

RUN apt-get update -y && \
    apt-get install -y --no-install-recommends wget git ca-certificates && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /repositories

ARG CACHE_BUST=4
RUN echo "CACHE_BUST=$CACHE_BUST" && \
    git clone --depth 1 --branch master https://github.com/ProjectIgnis/CardScripts.git edopro-card-scripts && \
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

RUN bash -c 'set -e; \
    declare -A MAP=( \
    ["2010.03 Edison(Pre Errata)"]="edison" \
    ["2014.04 HAT (Pre Errata)"]="hat" \
    ["jtp-oficial"]="jtp" \
    ["GOAT"]="goat" \
    ["Rush"]="rush" \
    ["Speed"]="speed" \
    ["Tengu.Plant"]="tengu" \
    ["World"]="world" \
    ["MD.2025.03"]="md" \
    ["Genesys"]="genesys" \
    ); \
    for name in "${!MAP[@]}"; do \
    src="./edopro-banlists-evolution/${name}.lflist.conf"; \
    [ -f "$src" ] || src="./edopro-banlists-ignis/${name}.lflist.conf"; \
    cp "$src" "./ygopro-format-alternatives/${MAP[$name]}/lflist.conf"; \
    done'

RUN find . -name ".git" -type d -exec rm -rf {} + 2>/dev/null; \
    mkdir -p /resources/edopro \
             /resources/ygopro/base \
             /resources/ygopro/ocg && \
    cp -r edopro-card-scripts /resources/edopro/scripts && \
    cp -r edopro-card-databases /resources/edopro/databases && \
    cp -r edopro-banlists-ignis /resources/edopro/banlists-ignis && \
    cp -r edopro-banlists-evolution /resources/edopro/banlists-evolution && \
    cp -r ygopro-scripts /resources/ygopro/base/script && \
    cp ygopro-lflist.conf /resources/ygopro/base/lflist.conf && \
    cp ygopro-cards.cdb /resources/ygopro/base/cards.cdb && \
    cp -r ygopro-prereleases-cdb /resources/ygopro/prereleases-cdb && \
    cp -r ygopro-cards-art /resources/ygopro/cards-art && \
    cp -r ygopro-format-alternatives /resources/ygopro/alternatives && \
    cp edopro-banlists-ignis/OCG.lflist.conf /resources/ygopro/ocg/lflist.conf && \
    cp -r realm-of-kings/scripts/* /resources/edopro/scripts/ && \
    find realm-of-kings -maxdepth 1 -name "*.cdb" -exec cp {} /resources/edopro/databases/ \; && \
    echo "##### REALM OF KINGS ROOT" && \
    ls -lh realm-of-kings/ || true && \
    echo "##### EDO DB FILES" && \
    ls -lh /resources/edopro/databases/ || true && \
    echo "##### EDO SCRIPT FILES" && \
    ls -lh /resources/edopro/scripts/ | head -50 || true

# Stage 2: Placeholder core stage (skip broken custom core build)
FROM public.ecr.aws/docker/library/node:24.11.0-bullseye-slim AS core-builder

WORKDIR /app
RUN mkdir -p /app/core && echo "Skipping custom core build"

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
FROM public.ecr.aws/docker/library/node:24.11.0-slim

RUN apt-get update && \
    apt-get install -y --no-install-recommends curl liblua5.3-dev libsqlite3-dev libevent-dev dumb-init && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /app

COPY --from=server-builder /server/dist ./dist
COPY --from=server-builder /server/package.json ./package.json
COPY --from=server-builder /server/node_modules ./node_modules

# Use prebuilt core files from repo output if present in dist/runtime layout
# If your app already includes/ships these elsewhere, keep these paths aligned with your server code.
COPY core/libocgcore.so ./core/libocgcore.so
COPY core/CoreIntegrator ./core/CoreIntegrator

COPY --from=resources-builder /resources ./resources

ENV LD_LIBRARY_PATH=/app/core
CMD ["dumb-init", "node", "./dist/src/index.js"]
