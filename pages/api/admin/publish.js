import fs from "fs";
import { join } from "path";

export default function handler(req, res) {
  if (req.method !== "POST") {
    return res.status(405).json({ message: "Method not allowed" });
  }

  // Check for admin password in environment variable or request
  const adminPassword = process.env.ADMIN_PASSWORD || "admin123"; // Default password, should be set in production
  const providedPassword = req.headers["x-admin-password"] || req.body.password;

  if (!providedPassword || providedPassword !== adminPassword) {
    return res.status(401).json({ message: "Unauthorized: Invalid admin password" });
  }

  const portfolioData = join(process.cwd(), "/data/portfolio.json");
  
  try {
    // Write the portfolio data to the file
    fs.writeFileSync(
      portfolioData,
      JSON.stringify(req.body.data, null, 2),
      "utf-8"
    );
    
    res.status(200).json({ 
      status: "DONE", 
      message: "Portfolio published to production successfully" 
    });
  } catch (err) {
    console.error("Error publishing portfolio:", err);
    res.status(500).json({ 
      status: "ERROR", 
      message: "Failed to publish portfolio to production" 
    });
  }
}

