import express, { Express } from "express";
import { config } from "src/config";
import { Logger } from "../shared/logger/domain/Logger";
import { createDirectoryIfNotExists } from "../utils";
import { loadRoutes } from "./routes";

export class Server {
  private readonly app: Express;
  private readonly logger: Logger;

  constructor(logger: Logger) {
    this.logger = logger;
    this.app = express();
    this.app.use(express.json());

    this.app.use((req, res, next) => {
      const origin = req.headers.origin;
      if (
        origin &&
        (config.allowedOrigins.includes("*") ||
          config.allowedOrigins.includes(origin))
      ) {
        res.header("Access-Control-Allow-Origin", origin);
      }

      res.header(
        "Access-Control-Allow-Methods",
        "GET, POST, OPTIONS, PUT, DELETE",
      );

      res.header(
        "Access-Control-Allow-Headers",
        "Origin, X-Requested-With, Content-Type, Accept, Authorization, admin-api-key",
      );

      if (req.method === "OPTIONS") {
        res.sendStatus(200);
      } else {
        next();
      }
    });

    this.app.get("/health", (_req, res) => {
      res.status(200).json({
        status: "online",
        uptime: process.uptime(),
      });
    });

    loadRoutes(this.app, this.logger);
  }

  async initialize(): Promise<void> {
    await createDirectoryIfNotExists("./config");

    // ✅ Railway-compatible port handling
    const httpPort =
      Number(process.env.PORT) ||
      config.servers.http.port ||
      7922;

    this.app.listen(httpPort, () => {
      this.logger.info(`Server listen in port ${httpPort}`);
    });
  }
}
