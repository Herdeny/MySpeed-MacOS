import os from 'node:os';
import https from 'node:https';
import * as config from '../controller/config.js';

export let interfaces = {};

export const requestInterfaces = async () => {
    const interfacesNode = os.networkInterfaces();
    const candidates = [];
    console.log("Looking for network interfaces...");
    for (const [name, addresses] of Object.entries(interfacesNode)) {
        for (const address of addresses ?? []) {
            const isLinkLocalV6 = address.family === "IPv6" && address.address.toLowerCase().startsWith("fe80:");
            if (!address.internal && !isLinkLocalV6) candidates.push({name, address});
        }
    }

    const probes = await Promise.all(candidates.map(({name, address}) => new Promise((resolve) => {
        const options = {
            hostname: "speed.cloudflare.com",
            path: "/__down?bytes=1",
            method: "GET",
            family: address.family === "IPv4" ? 4 : 6,
            timeout: 3000,
            localAddress: address.address
        };
        options.agent = new https.Agent(options);

        let settled = false;
        const finish = (reachable) => {
            if (settled) return;
            settled = true;
            clearTimeout(hardTimeout);
            resolve({name, address, reachable});
        };
        const req = https.request(options, () => {
            finish(true);
            req.destroy();
        });
        const hardTimeout = setTimeout(() => {
            finish(false);
            req.destroy();
        }, 3500);
        req.on('error', () => finish(false));
        req.on('timeout', () => {
            finish(false);
            req.destroy();
        });
        req.end();
    })));

    let usable = probes.filter(candidate => candidate.reachable);
    if (usable.length === 0 && candidates.length > 0) {
        usable = candidates.map(candidate => ({...candidate, reachable: false}));
        console.warn("Interface reachability probe failed; falling back to local active interfaces.");
    }

    const nextInterfaces = {};
    for (const {name, address} of usable) {
        if (!nextInterfaces[name] || address.family === "IPv4") nextInterfaces[name] = address.address;
    }
    interfaces = nextInterfaces;

    for (const [name, address] of Object.entries(interfaces)) {
        console.log(`Found interface ${name} with IP ${address}`);
    }

    const currentInterface = await config.getValue("interface");

    if (!interfaces[currentInterface]) {
        if (!currentInterface) {
            console.warn("No interface set. Falling back to default.");
        } else {
            console.warn(`Interface ${currentInterface} not found. Falling back to default.`);
        }
        const fallback = Object.keys(interfaces)[0];
        if (fallback) await config.updateValue("interface", fallback);
    }
};
