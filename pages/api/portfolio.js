import fs from "fs";
import { join } from "path";

export default function handler(req, res) {
  const portfolioData = join(process.cwd(), "/data/portfolio.json");
  
  // Allow in development mode OR if admin password is provided
  const adminPassword = process.env.ADMIN_PASSWORD || "admin123";
  const providedPassword = req.headers["x-admin-password"] || req.body.password;
  const isAuthorized = process.env.NODE_ENV === "development" || 
                       (providedPassword && providedPassword === adminPassword);

  if (req.method === "POST") {
    if (isAuthorized) {
      try {
        fs.writeFileSync(
          portfolioData,
          JSON.stringify(req.body.data || req.body, null, 2),
          "utf-8"
        );
        res.status(200).json({ 
          status: "DONE", 
          message: process.env.NODE_ENV === "development" 
            ? "Portfolio saved successfully" 
            : "Portfolio saved successfully (production mode)" 
        });
      } catch (err) {
        console.error("Error saving portfolio:", err);
        res.status(500).json({ status: "ERROR", message: "Failed to save portfolio" });
      }
    } else {
      res.status(401).json({ message: "Unauthorized: Admin password required in production mode" });
    }
  } else {
    res.status(200).json({ name: "Portfolio API endpoint" });
  }
}
