import * as libreProvider from './providers/loadLibre.js';
import * as ooklaProvider from './providers/loadOokla.js';
import * as cloudflareProvider from './providers/loadCloudflare.js';

export const load = async () => {
    const providers = [
        ["LibreSpeed", libreProvider],
        ["Ookla", ooklaProvider],
        ["Cloudflare", cloudflareProvider]
    ];

    const results = await Promise.allSettled(providers.map(async ([name, provider]) => {
        if (name === "Ookla" && process.env.MYSPEED_SKIP_OOKLA_DOWNLOAD === "true" && !await provider.fileExists()) {
            throw new Error("not bundled; official download is disabled for this launch");
        }
        await provider.load();
    }));
    results.forEach((result, index) => {
        const [name] = providers[index];
        if (result.status === "fulfilled") console.log(`${name} provider ready.`);
        else console.warn(`${name} provider unavailable: ${result.reason?.message || result.reason}`);
    });
};
