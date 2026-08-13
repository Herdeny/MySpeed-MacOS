import fs from 'node:fs';
import { LIBRE_CN_SERVERS, OOKLA_CN_SERVERS } from '../config/cnServers.js';

let ooklaServers;
let libreServers;

export const getLibreServers = () => {
    if (libreServers) return libreServers;

    let servers = {};
    if (fs.existsSync("./data/servers/librespeed.json")) {
        try {
            servers = JSON.parse(fs.readFileSync("./data/servers/librespeed.json", "utf8"));
        } catch {
            console.warn("Could not parse cached LibreSpeed servers; using bundled China nodes.");
        }
    }

    libreServers = {...servers, ...LIBRE_CN_SERVERS};
    return libreServers;
}

export const getOoklaServers = () => {
    if (ooklaServers) return ooklaServers;

    let servers = {};
    if (fs.existsSync("./data/servers/ookla.json")) {
        try {
            servers = JSON.parse(fs.readFileSync("./data/servers/ookla.json", "utf8"));
        } catch {
            console.warn("Could not parse cached Ookla servers; using bundled China nodes.");
        }
    }

    ooklaServers = {...servers, ...OOKLA_CN_SERVERS};
    return ooklaServers;
}

export const getByMode = (mode) => {
    if (mode === "ookla") return getOoklaServers();
    if (mode === "libre") return getLibreServers();
}
