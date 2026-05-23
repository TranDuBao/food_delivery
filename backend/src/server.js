require("dotenv").config();

const app = require("./app");
const { testConnection } = require("./config/db");
const { startCronJobs } = require("./services/cronJobService");

const port = Number(process.env.PORT || 3001);
const host = process.env.HOST || "0.0.0.0";

async function bootstrap() {
  try {
    await testConnection();
    app.listen(port, host, () => {
      console.log(`Backend listening on http://${host}:${port}`);
      // Khởi động cron job sau khi server lên
      startCronJobs();
    });
  } catch (error) {
    console.error("Failed to start backend:", error.message);
    process.exit(1);
  }
}

bootstrap();
