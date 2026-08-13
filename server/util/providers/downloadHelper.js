import fs from 'node:fs';
import os from 'node:os';
import path from 'node:path';
import { get } from 'node:https';
import { randomBytes } from 'node:crypto';
import decompress from 'decompress';
import decompressTarGz from 'decompress-targz';
import decompressUnzip from 'decompress-unzip';

export const tmpFile = (suffix = '') =>
    path.join(os.tmpdir(), randomBytes(16).toString('hex') + suffix);

export const downloadToFile = (url, destPath) => new Promise((resolve, reject) => {
    get(url, (res) => {
        if (res.statusCode >= 300 && res.statusCode < 400 && res.headers.location) {
            res.resume();
            return resolve(downloadToFile(res.headers.location, destPath));
        }
        if (res.statusCode !== 200) {
            res.resume();
            return reject(new Error(`Download failed: ${url} returned ${res.statusCode}`));
        }
        const writeStream = fs.createWriteStream(destPath);
        res.pipe(writeStream);
        writeStream.on('finish', () => resolve());
        writeStream.on('error', reject);
        res.on('error', reject);
    }).on('error', reject);
});

export const extractBinary = async (archivePath, outputDir, binaryRegex, outputName) => {
    await decompress(archivePath, outputDir, {
        plugins: [decompressTarGz(), decompressUnzip()],
        filter: file => binaryRegex.test(file.path),
        map: file => {
            file.path = outputName;
            return file;
        }
    });
    if (process.platform !== 'win32') fs.chmodSync(path.join(outputDir, outputName), 0o755);
};
