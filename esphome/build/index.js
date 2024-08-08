const mdns = require("node-dns-sd");
const fs = require("fs");

async function discovery(name = "_esphomelib._tcp.local", wait = 3) {
  return await new Promise((resolve, reject) => {
    mdns
      .discover({
        name: name,
        wait: wait,
      })
      .then((items) => {
        const devices = [];
        items
          .sort((a, b) => (a.fqdn > b.fqdn ? 1 : -1))
          .map((device) => {
            devices.push({
              host: device.address,
              port: device.service.port,
              fqdn: device.fqdn.replace(/_esphomelib\._tcp./gi, ""),
            });
          });

        resolve(devices);
      })
      .catch((e) => {
        reject(e);
      });
  });
}
let old = "";
async function main() {
  while (1) {
    const out = await discovery();
    const discovered = {
      targets: out.map((i) => i.host),
      labels: { esphome: "esphome" },
    };
    const data = JSON.stringify([discovered], null, 2);

    if (data != old) {
      old = data;
      fs.writeFileSync(process.env.OUTPUT_FILE, data);
      console.log("Discovery: ", discovered.targets.join(", "));
    }

    await new Promise((resolve) => setTimeout(resolve, 10000));
  }
}

/*
[
  {
    "targets": [ "192.168.1.156" ],
    "labels": {
      "esphome": "esphome"
    }
  }
]
*/
main();

