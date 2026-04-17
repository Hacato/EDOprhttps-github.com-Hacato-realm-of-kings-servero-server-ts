import "reflect-metadata";
import "./shared/error-handler/error-handler";

import fs from "fs";
import path from "path";

import { EdoProBanListLoader } from "./edopro/ban-list/infrastructure/BanListLoader";
import { EdoProSQLiteTypeORM } from "./shared/db/sqlite/infrastructure/EdoProSQLiteTypeORM";
import LoggerFactory from "./shared/logger/infrastructure/LoggerFactory";

import { config } from "./config";
import { PostgresTypeORM } from "./evolution-types/src/PostgresTypeORM";
import { Server } from "./http-server/Server";
import { YGOProBanListLoader } from "./ygopro/ban-list/infrastructure/YGOProBanListLoader";
import { YGOProResourceLoader } from "./ygopro/ygopro/YGOProResourceLoader";
import { HostServer } from "./socket-server/HostServer";
import { WSHostServer } from "./socket-server/WSHostServer";
import { YGOProServer } from "./socket-server/YGOProServer";
import WebSocketSingleton from "./web-socket-server/WebSocketSingleton";

start().catch((error) => {
  console.error(error);
  process.exit(1);
});

async function start(): Promise<void> {
  const logger = LoggerFactory.getLogger();

  // 🔍 DEBUG: confirm startup + ports
  console.log("BOOT_CHECK", {
    httpPort: config.servers.http.port,
    mercuryPort: config.servers.mercury.port,
    websocketPort: config.servers.websocket.port,
    duelPort: config.servers.websocket.duelPort,
  });

  // 🔍 DEBUG: confirm custom card repo + folders are visible in container
  const repoRoot = "./repositories/Realm-Of-Kings";
  const scriptDir = path.join(repoRoot, "script");
  const dbDir = path.join(repoRoot, "expansions");
  const picsDir = path.join(repoRoot, "pics");

  console.log("CUSTOM_CARD_DEBUG", {
    repoRootExists: fs.existsSync(repoRoot),
    scriptDirExists: fs.existsSync(scriptDir),
    dbDirExists: fs.existsSync(dbDir),
    picsDirExists: fs.existsSync(picsDir),
    repoRootFiles: fs.existsSync(repoRoot) ? fs.readdirSync(repoRoot) : [],
    scriptFilesSample: fs.existsSync(scriptDir)
      ? fs.readdirSync(scriptDir).slice(0, 10)
      : [],
    dbFiles: fs.existsSync(dbDir) ? fs.readdirSync(dbDir) : [],
    picsFilesSample: fs.existsSync(picsDir)
      ? fs.readdirSync(picsDir).slice(0, 10)
      : [],
    YGOPRO_FOLDERS: process.env.YGOPRO_FOLDERS,
    YGOPRO_EXTRA_DB_FOLDERS: process.env.YGOPRO_EXTRA_DB_FOLDERS,
    YGOPRO_EXTRA_SCRIPTS: process.env.YGOPRO_EXTRA_SCRIPTS,
  });

  const server = new Server(logger);
  const ygoproServer = new YGOProServer(logger);
  const hostServer = new HostServer(logger);
  const wsHostServer = new WSHostServer(logger);

  const database = new EdoProSQLiteTypeORM();
  const banListLoader = new EdoProBanListLoader();

  await banListLoader.loadDirectory("resources/edopro/banlists-evolution");
  await banListLoader.loadDirectory("resources/edopro/banlists-ignis");

  await YGOProResourceLoader.start();
  await YGOProResourceLoader.get().logLFLists();

  const ygoProBanListLoader = new YGOProBanListLoader();
  await ygoProBanListLoader.load();

  await database.connect();
  await database.initialize();

  if (config.ranking.enabled) {
    logger.info("Postgres database enabled!");
    const postgresDatabase = new PostgresTypeORM();
    await postgresDatabase.connect();
  }

  await server.initialize();
  WebSocketSingleton.getInstance();
  hostServer.initialize();
  wsHostServer.initialize();
  ygoproServer.initialize();
}
