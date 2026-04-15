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

  // 👇 ADD THIS HEALTH ROUTE
  this.app.get("/", (_req, res) => {
    res.status(200).send("Server is running");
  });

  loadRoutes(this.app, this.logger);
}
