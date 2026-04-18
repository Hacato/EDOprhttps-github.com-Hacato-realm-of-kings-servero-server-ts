Load more

resources-builder
RUN echo "DOWNLOAD_BUST=3" &&     git clone --depth 1 --branch master https://github.com/ProjectIgnis/CardScripts.git edopro-card-scripts &&     git clone --depth 1 --branch master https://github.com/ProjectIgnis/BabelCDB.git edopro-card-databases &&     git clone --depth 1 --branch master https://github.com/ProjectIgnis/LFLists edopro-banlists-ignis &&     git clone --depth 1 --branch main https://github.com/termitaklk/lflist edopro-banlists-evolution &&     git clone --depth 1 https://code.moenext.com/nanahira/ygopro-scripts ygopro-scripts &&     git clone --depth 1 --branch master https://github.com/evolutionygo/pre-release-database-cdb ygopro-prereleases-cdb &&     git clone --depth 1 --branch main https://github.com/evolutionygo/cards-art-server ygopro-cards-art &&     git clone --depth 1 --branch main https://github.com/evolutionygo/server-formats-cdb.git ygopro-format-alternatives &&     git clone --depth 1 --branch main https://github.com/Hacato/Realm-Of-Kings.git realm-of-kings &&     wget --no-cache -O ygopro-lflist.conf https://cdntx.moecube.com/ygopro-database/zh-CN/lflist.conf &&     wget --no-cache -O ygopro-cards.cdb https://cdntx.moecube.com/ygopro-database/zh-CN/cards.cdb
55s
2026-04-18 14:51:25 (3.57 MB/s) - 'ygopro-cards.cdb' saved [7785472/7785472]

stage-3
COPY --from=server-builder /server/node_modules ./node_modules
1s

stage-3
RUN npm rebuild better-sqlite3
2s
npm notice

stage-3
COPY --from=core-builder /app/core/libocgcore.so ./core/libocgcore.so
37ms

stage-3
COPY --from=core-builder /app/core/CoreIntegrator ./core/CoreIntegrator
33ms

resources-builder
RUN mkdir -p /resources/edopro/scripts     /resources/edopro/databases     /resources/edopro/banlists-ignis     /resources/edopro/banlists-evolution     /resources/edopro/pics     /resources/ygopro/base/script     /resources/ygopro/prereleases-cdb     /resources/ygopro/cards-art     /resources/ygopro/alternatives     /resources/ygopro/ocg
354ms

resources-builder
RUN cp -r edopro-card-scripts/* /resources/edopro/scripts/ &&     cp -r edopro-card-databases/* /resources/edopro/databases/ &&     cp -r edopro-banlists-ignis/* /resources/edopro/banlists-ignis/ &&     cp -r edopro-banlists-evolution/* /resources/edopro/banlists-evolution/ &&     cp -r ygopro-scripts/* /resources/ygopro/base/script/ &&     cp ygopro-lflist.conf /resources/ygopro/base/lflist.conf &&     cp ygopro-cards.cdb /resources/ygopro/base/cards.cdb &&     cp -r ygopro-prereleases-cdb/* /resources/ygopro/prereleases-cdb/ &&     cp -r ygopro-cards-art/* /resources/ygopro/cards-art/ &&     cp -r ygopro-format-alternatives/* /resources/ygopro/alternatives/ &&     cp edopro-banlists-ignis/OCG.lflist.conf /resources/ygopro/ocg/lflist.conf &&     cp -r realm-of-kings/scripts/* /resources/edopro/scripts/ &&     find realm-of-kings -maxdepth 1 -name "*.cdb" -exec cp {} /resources/edopro/databases/ ; &&     if [ -d "realm-of-kings/pics" ]; then cp -r realm-of-kings/pics/* /resources/edopro/pics/; fi &&     chmod -R a+r /resources &&     echo "##### DATABASE FILES (build)" &&     ls -lh /resources/edopro/databases/ &&     echo "##### SCRIPT FILES (build)" &&     ls -lh /resources/edopro/scripts/ &&     echo "##### IMAGE FILES (build)" &&     ls -lh /resources/edopro/pics/ || true
11s
cp: cannot stat 'realm-of-kings/scripts/*': No such file or directory

stage-3
COPY --from=resources-builder /resources ./resources
4s

stage-3
RUN echo "CACHE_BUST=2" &&     echo "##### DATABASE FILES (/app/resources)" &&     ls -lh /app/resources/edopro/databases/ &&     echo "##### SCRIPT FILES (/app/resources)" &&     ls -lh /app/resources/edopro/scripts/ &&     echo "##### IMAGE FILES (/app/resources)" &&     ls -lh /app/resources/edopro/pics/ &&     echo "##### BANLIST FILES (/app/resources)" &&     ls -lh /app/resources/edopro/banlists-evolution/ &&     echo "##### YGOPRO BASE FILES (/app/resources)" &&     ls -lh /app/resources/ygopro/base/ || true
299ms
drwxr-xr-x 3 root root 472K Apr 18 14:51 script

auth
sharing credentials for production-us-west2.railway-registry.com
0ms

importing to docker
22s
Build time: 120.33 seconds

Load more
