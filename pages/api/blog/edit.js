import fs from "fs";
import { join } from "path";
import matter from "gray-matter";

export default function handler(req, res) {
  const postsfolder = join(process.cwd(), `/_posts/`);
  if (process.env.NODE_ENV === "development") {
    if (req.method === "POST") {
      const { date, title, tagline, preview, image } = req.body.variables;
      fs.writeFile(
        postsfolder + req.body.slug + ".md",
        matter.stringify(req.body.content, {
          date,
          title,
          tagline,
          preview,
          image,
        }),
        "utf-8",
        (err) => {
          if (err) {
            console.error("Error saving blog post:", err);
            res.status(500).json({ status: "ERROR", message: "Failed to save blog post" });
          } else {
            res.status(200).json({ status: "DONE" });
          }
        }
      );
    } else {
      res
        .status(200)
        .json({ name: "This route works in development mode only" });
    }
  } else {
    res.status(403).json({ message: "This route works in development mode only" });
  }
}
