# Stage 1: Clone repositories and assemble resources
FROM public.ecr.aws/docker/library/node:24.11.0-bullseye-slim AS resources-builder

RUN apt-get update -y && \
    apt-get install -y --no-install-recommends wget git ca-certificates && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /repositories

ARG CACHE_BUST=5
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
    wget --no-cache -O ygopro-lflist.conf https://cdntx.moecube.com/ygopro-database/zh-CN/lflist.conf && \
    wget --no-cache -O ygopro-cards.cdb https://cdntx.moecube.com/ygopro-database/zh-CN/cards.cdb

RUN mkdir -p /resources/edopro/scripts \
    /resources/edopro/databases \
    /resources/edopro/banlists-ignis \
    /resources/edopro/banlists-evolution \
    /resources/edopro/pics \
    /resources/ygopro/base/script \
    /resources/ygopro/prereleases-cdb \
    /resources/ygopro/cards-art \
    /resources/ygopro/alternatives \
    /resources/ygopro/ocg

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
    cp -r realm-of-kings/script/* /resources/edopro/scripts/ && \
    find realm-of-kings -maxdepth 1 -name "*.cdb" -exec cp {} /resources/edopro/databases/ \; && \
    if [ -d "realm-of-kings/pics" ]; then cp -r realm-of-kings/pics/* /resources/edopro/pics/; fi && \
    chmod -R a+r /resources && \
    echo "##### DATABASE FILES (build)" && \
    ls -lh /resources/edopro/databases/ && \
    echo "##### CHECK FOR YOUR DATABASE" && \
    ls -lh /resources/edopro/databases/ | grep -i "realm" || true && \
    echo "##### SCRIPT FILES (build)" && \
    ls -lh /resources/edopro/scripts/ && \
    echo "##### CHECK FOR YOUR SCRIPT" && \
    ls -lh /resources/edopro/scripts/ | grep -i "charizard" || true && \
    echo "##### IMAGE FILES (build)" && \
    ls -lh /resources/edopro/pics/ || true
