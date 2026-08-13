import fs from 'node:fs';
import { getJson } from './http.js';
import { LIBRE_CN_SERVERS, OOKLA_CN_SERVERS } from '../config/cnServers.js';

const sources = [
    {
        file: "data/servers/ookla.json",
        url: "https://www.speedtest.net/api/js/servers?limit=20",
        format: (row) => ({
            name: row.name,
            sponsor: row.sponsor,
            country: row.country,
            cc: row.cc,
            distance: row.distance,
            host: row.host
        }),
        isCurrent: (entries) => entries.length === 0 || entries.every(([, value]) =>
            value !== null && typeof value === "object" && "sponsor" in value && "name" in value)
    },
    {
        file: "data/servers/librespeed.json",
        url: "https://librespeed.org/backend-servers/servers.php",
        format: (row) => row.name,
        isCurrent: () => true
    }
];

const isFileCurrent = (file, isCurrent) => {
    try {
        const parsed = JSON.parse(fs.readFileSync(file, "utf8"));
        if (parsed === null || typeof parsed !== "object") return false;
        return isCurrent(Object.entries(parsed));
    } catch {
        return false;
    }
};

for (const {file, url, format, isCurrent} of sources) {
    if (fs.existsSync(file) && isFileCurrent(file, isCurrent)) continue;

    getJson(url)
        .then((data) => {
            let servers = Object.fromEntries((data ?? []).map((row) => [row.id, format(row)]));
            if (file.includes("ookla")) servers = {...servers, ...OOKLA_CN_SERVERS};
            if (file.includes("librespeed")) servers = {...servers, ...LIBRE_CN_SERVERS};
            fs.writeFileSync(file, JSON.stringify(servers, null, 4));
        })
        .catch(() => {
            const bundled = file.includes("ookla") ? OOKLA_CN_SERVERS : LIBRE_CN_SERVERS;
            if (!fs.existsSync(file)) fs.writeFileSync(file, JSON.stringify(bundled, null, 4));
            console.error("Could not load public servers; bundled China nodes remain available.");
        });
}
