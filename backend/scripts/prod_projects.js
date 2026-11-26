const fs = require("fs");
const path = require("path");

/** The production project ids: the `prod` alias in .firebaserc. */
function prodProjectsFromConfig(file = path.join(__dirname, "../../.firebaserc")) {
  try {
    const prod = JSON.parse(fs.readFileSync(file, "utf8")).projects.prod;
    return typeof prod === "string" && prod ? [prod] : [];
  } catch (_) {
    return [];
  }
}

module.exports = { prodProjectsFromConfig };
