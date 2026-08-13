import { spawn } from 'node:child_process';
import * as interfacesModule from '../util/loadInterfaces.js';
import * as config from '../controller/config.js';
import fs from 'node:fs';
import path from 'node:path';

export default async (mode, serverId, serverUrl) => {
    const binaryPath = mode === "ookla" ? './bin/speedtest' + (process.platform === "win32" ? ".exe" : "")
        : mode === "libre" ? './bin/librespeed-cli' + (process.platform === "win32" ? ".exe" : "")
            : './bin/cfspeedtest' + (process.platform === "win32" ? ".exe" : "");

    if (!fs.existsSync(binaryPath)) {
        throw new Error(`Speed test provider is missing: ${binaryPath}`);
    }

    if (!interfacesModule.interfaces) throw new Error("No interfaces found");

    const currentInterface = await config.getValue("interface");
    const interfaceIp = interfacesModule.interfaces[currentInterface];

    const startTime = new Date().getTime();
    let args;

    if (mode === "ookla") {
        args = ['--accept-license', '--accept-gdpr', '--format=json'];

        if (process.platform === "win32") {
            args.push('--ip=' + interfaceIp);
        } else {
            args.push('--interface=' + currentInterface);
        }

        if (serverId) args.push(`--server-id=${serverId}`);
    } else if (mode === "libre") {
        args = ['--json', '--duration=5'];
        // librespeed-cli's source-address binding is unreliable on macOS and can
        // reject an otherwise reachable server. Let the macOS route table select
        // the interface; explicit binding remains available on other platforms.
        if (process.platform === "darwin") args.push('--no-icmp');
        else args.push('--source=' + interfaceIp);
        if (serverUrl) {
            const customServerConfig = [{
                id: 1,
                name: "Custom Server",
                server: serverUrl,
                dlURL: "garbage.php",
                ulURL: "empty.php",
                pingURL: "empty.php",
                getIpURL: "getIP.php"
            }];
            const tempJsonPath = path.join('data', 'servers', 'libre_custom.json');
            fs.writeFileSync(tempJsonPath, JSON.stringify(customServerConfig));
            args.push(`--local-json=${tempJsonPath}`);
            args.push('--server=1');
        } else if (serverId) {
            if (/[^0-9]/.test(String(serverId))) {
                const {getLibreServers} = await import('../controller/servers.js');
                const selected = getLibreServers()[serverId];
                if (!selected || typeof selected !== "object") {
                    throw new Error(`Unknown LibreSpeed server: ${serverId}`);
                }
                const tempJsonPath = path.join('data', 'servers', 'libre_selected.json');
                fs.writeFileSync(tempJsonPath, JSON.stringify([{
                    id: 1,
                    name: selected.name || String(serverId),
                    server: selected.server,
                    dlURL: selected.dlURL || "garbage.php",
                    ulURL: selected.ulURL || "empty.php",
                    pingURL: selected.pingURL || "empty.php",
                    getIpURL: selected.getIpURL || "getIP.php"
                }]));
                args.push(`--local-json=${tempJsonPath}`, '--server=1');
            } else {
                args.push(`--server=${serverId}`);
            }
        }
    } else if (mode === "cloudflare") {
        args = ['--output-format=json'];

        if (interfaceIp.includes(':')) {
            args.push('--ipv6=' + interfaceIp);
        } else {
            args.push('--ipv4=' + interfaceIp);
        }
    }

    let result = {};
    let stdout = '';

    const testProcess = spawn(binaryPath, args, {windowsHide: true});

    testProcess.stderr.on('data', (buffer) => {
        result.error = buffer.toString();
        if (buffer.toString().includes("Too many requests")) {
            result.error = "Too many requests. Please try again later";
        }
    });

    testProcess.stdout.on('data', (buffer) => {
        stdout += buffer.toString();
    });

    await new Promise((resolve, reject) => {
        testProcess.on('error', e => reject({message: e}));
        testProcess.on('exit', () => {
            if (stdout.trim()) {
                const lines = stdout.trim().split('\n');
                for (const line of lines) {
                    if (!(line.startsWith("{") || line.startsWith("["))) continue;

                    let data = {};
                    try {
                        data = JSON.parse(line);
                        if (line.startsWith("[") && mode !== "cloudflare") data = data[0];
                    } catch (e) {
                        data.error = e.message;
                        console.error("JSON parse error:", e.message, "Line:", line);
                        continue;
                    }

                    if (data.error) result.error = data.error;

                    if ((mode === "ookla" && data.type === "result") || mode === "libre" || mode === "cloudflare") {
                        result = data;
                    }
                }
            }
            resolve();
        });
    });

    if (result.error) throw new Error(result.error);
    return {...result, elapsed: new Date().getTime() - startTime};
}
