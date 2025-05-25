import fs from "fs";
import { execSync } from "child_process";

const monitors = JSON.parse(fs.readFileSync(new URL("../monitors.json", import.meta.url), "utf-8"));

function parseHyprctlOutput(output) {
  const lines = output.split("\n").filter(line => line.trim() !== "");
  const monitors = [];
  let currentMonitor = {};

  for (const line of lines) {
    if (line.startsWith("Monitor")) {
      if (Object.keys(currentMonitor).length > 0) {
        monitors.push(currentMonitor);
      }
      currentMonitor = { name: line.split(" ")[1] };
    } else {
      const [key, value] = line.split(":").map(part => part.trim());
      if (key && value) {
        currentMonitor[key] = value;
      }
    }
  }

  if (Object.keys(currentMonitor).length > 0) {
    monitors.push(currentMonitor);
  }

  return monitors;
}

const hyprctlOutput = execSync("hyprctl monitors all", { encoding: "utf-8" });
const parsedMonitors = parseHyprctlOutput(hyprctlOutput);


parsedMonitors.forEach(monitor => {
  if (monitor.model in monitors) {

    console.log(`hyprctl keyword monitor ${monitor.name}, ${monitors[monitor.model]}`)

    execSync(`hyprctl keyword monitor ${monitor.name}, ${monitors[monitor.model]}`, { stdio: "inherit" });
  }
});
