const fs = require("fs");
const path = require("path");
const axios = require("axios");

const oas = fs.readFileSync(path.join(__dirname, "../oas/products.yml"));
const report = fs.readFileSync(path.join(__dirname, "../output/report.md"));
const success = process.argv[2];
const version = process.argv[3] || process.env.GIT_COMMIT;

const result = {
  content: Buffer.from(oas, "utf-8").toString("base64"),
  contractType: "oas",
  contentType: "application/yaml",
  verificationResults: {
    success: success === "true",
    content: Buffer.from(report, "utf-8").toString("base64"),
    contentType: "text/plain",
    verifier: "verifier",
  },
};

console.log("Publishing OAS + results to Pactflow", result);

// Upload the contract + results together
axios({
  method: "PUT",
  headers: {
    Authorization: `Bearer ${process.env.PACT_BROKER_TOKEN}`,
    "Content-Type": "application/json",
  },
  url:
    process.env.PACT_BROKER_BASE_URL +
    `/contracts/provider/pactflow-example-bi-directional-provider-dredd/version/${version}`,
  data: result,
})
  .then(() => {
    console.log("done.");
  })
  .catch((error) => {
    console.log("error publishing contract + results", error);
    process.exit(1);
  });
