import fs from 'node:fs';
import path from 'node:path';
import { ooklaVersion, ooklaList } from '../../config/binaries.js';
import { tmpFile, downloadToFile, extractBinary } from './downloadHelper.js';

const binaryName = `speedtest${process.platform === 'win32' ? '.exe' : ''}`;
const binaryRegex = /speedtest(.exe)?$/;
const binaryDirectory = path.join(process.cwd(), 'bin');
const binaryPath = path.join(binaryDirectory, binaryName);

const downloadPath = `https://install.speedtest.net/app/cli/ookla-speedtest-${ooklaVersion}-`;

export const fileExists = async () => fs.existsSync(binaryPath);

export const downloadFile = async () => {
    let binary = ooklaList.find(b => b.os === process.platform && b.arch === process.arch);
    // Ookla only publishes an Intel macOS CLI. Apple Silicon can run it via Rosetta.
    if (!binary && process.platform === 'darwin' && process.arch === 'arm64')
        binary = ooklaList.find(b => b.os === 'darwin' && b.arch === 'x64');
    if (!binary)
        throw new Error(`Your platform (${process.platform}-${process.arch}) is not supported by the Speedtest CLI`);

    const archivePath = tmpFile(binary.suffix);
    await downloadToFile(downloadPath + binary.suffix, archivePath);
    await extractBinary(archivePath, binaryDirectory, binaryRegex, binaryName);
};

export const load = async () => {
    if (!await fileExists()) await downloadFile();
};
