import config from '../models/Config.js';
import node from '../models/Node.js';
import test from '../models/Speedtests.js';
import recommendations from '../models/Recommendations.js';
import integration from '../models/IntegrationData.js';
import { triggerEvent } from './integrations.js';
import bcrypt from 'bcryptjs';
import * as timer from '../tasks/timer.js';
import cron from 'cron-validator';
import db from '../config/database.js';
import fs from 'node:fs';
import path from 'node:path';
import * as interfaces from '../util/loadInterfaces.js';

const configDefaults = {
    ping: "25",
    download: "100",
    upload: "50",
    cron: "0 * * * *",
    scheduleOffset: "true",
    provider: process.env.MYSPEED_DEFAULT_PROVIDER || "none",
    ooklaId: process.env.MYSPEED_DEFAULT_OOKLA_ID || "none",
    libreId: process.env.MYSPEED_DEFAULT_LIBRE_ID || "none",
    libreUrl: "none",
    password: "none",
    passwordLevel: "none",
    interface: "none",
    retentionDays: "365"
}

const MAX_RETENTION_DAYS = 10000;

export const insertDefaults = async () => {
    let insert = [];
    for (let key in configDefaults) {
        if (key !== "interface" && !(await config.findOne({where: {key: key}})))
            insert.push({key: key, value: configDefaults[key]});

        if (key === "interface") {
            const ips = Object.keys(interfaces.interfaces);
            let ip = ips.length > 0 ? ips[0] : "none";

            if (!(await config.findOne({where: {key: key}})))
                insert.push({key: key, value: ip});
        }
    }

    await config.bulkCreate(insert, {validate: true});
}

export const listAll = async () => {
    return await config.findAll();
}

export const getValue = async (key) => {
    return (await config.findByPk(key))?.value;
}

export const updateValue = async (key, newValue) => {
    if ((await getValue(key)) === undefined) return undefined;

    triggerEvent("configUpdated", {key: key, value: key === "password" ? "protected" : newValue})
        .then(undefined);

    return await config.update({value: newValue}, {where: {key: key}});
}

export const getUsedStorage = async () => {
    let size = 0;

    if (process.env.DB_TYPE === "mysql") {
        const sizes = await db.query("SELECT table_name AS `Table`, ROUND((data_length + index_length), 2) AS `size` FROM information_schema.TABLES WHERE table_schema = ?;", {
            replacements: [process.env.DB_NAME],
            type: db.QueryTypes.SELECT
        });
        for (let i = 0; i < sizes.length; i++) {
            size += parseFloat(sizes[i].size);
        }
    } else {
        const STORAGE_PATH = path.join(process.cwd(), 'data', `storage${process.env.PREVIEW_MODE === "true" ? "_preview" : ""}.db`);

        size = fs.statSync(STORAGE_PATH).size;
    }

    return {size, testCount: await test.count()};
}

export const validateInput = async (key, value) => {
    if (!value?.toString()) return "You need to provide the new value";

    if ((key === "ping" || key === "download" || key === "upload") && /[^0-9.]/.test(value))
        return "You need to provide a number in order to change this";

    if (key === "ooklaId" && (/[^0-9]/.test(value) && value !== "none"))
        return "You need to provide a number in order to change this";

    if (key === "libreUrl" && value !== "none") {
        try {
            new URL(value);
        } catch (e) {
            return "You need to provide a valid URL";
        }
    }

    if (key === "passwordLevel" && !["none", "read"].includes(value))
        return "You need to provide either none or read-access";

    if (key === "provider" && !["ookla", "libre", "cloudflare"].includes(value))
        return "You need to provide a valid provider";

    if (key === "ping")
        value = value.toString().split(".")[0];

    if (key === "password" && value !== "none")
        value = await bcrypt.hash(value, 10);

    if (key === "cron" && !cron.isValidCron(value.toString()))
        return "Not a valid cron expression";

    if (key === "scheduleOffset" && !["true", "false"].includes(value))
        return "You need to provide either true or false";

    if (key === "interface" && !Object.keys(interfaces.interfaces).includes(value))
        return "The provided interface does not exist";

    if (key === "retentionDays") {
        if (/[^0-9-]/.test(value.toString()))
            return "You need to provide a number in order to change this";

        const num = parseInt(value);
        if (isNaN(num))
            return "You need to provide a valid number";

        if (num <= 0) {
            value = "0";
        } else if (num > MAX_RETENTION_DAYS) {
            return `Retention must be ${MAX_RETENTION_DAYS} days or less (use 0 for unlimited)`;
        } else {
            value = num.toString();
        }
    }

    if (configDefaults[key] === undefined)
        return "The provided key does not exist";

    if (process.env.PREVIEW_MODE === "true" && (key === "password" || key === "passwordLevel"))
        return "You can't change the password in preview mode";

    return {value: value};
}

export const exportConfig = async () => {
    let obj = {};
    obj.config = {};

    let configValues = await config.findAll();
    for (let i = 0; i < configValues.length; i++) {
        if (configValues[i].key === "password" || configValues[i].key === "interface") continue;
        obj.config[configValues[i].key] = configValues[i].value;
    }

    obj.nodes = await node.findAll();
    obj.recommendations = await recommendations.findAll();

    obj.integrations = await integration.findAll();

    return obj;
}

export const importConfig = async (obj) => {
    let configValues = obj.config;
    for (let key in configValues) {
        if (configDefaults[key] === undefined) continue
        if (key === "password") continue;

        const validate = await validateInput(key, configValues[key]);
        if (Object.keys(validate).length !== 1) return false;

        if (key === "cron") {
            timer.stopTimer();
            timer.startTimer(configValues[key].toString());
        }

        await config.update({value: validate.value}, {where: {key: key}});
    }

    if (recommendations.length > 1) return false;

    await node.destroy({where: {}});
    await recommendations.destroy({where: {}});
    await integration.destroy({where: {}});

    try {
        await node.bulkCreate(obj.nodes);

        for (let i = 0; i < obj.integrations.length; i++) {
            obj.integrations[i].data = JSON.parse(obj.integrations[i].data);
        }

        await integration.bulkCreate(obj.integrations);

        await recommendations.bulkCreate(obj.recommendations);
    } catch (e) {
        return false;
    }

    return true;
}

export const factoryReset = async () => {
    let configValues = await config.findAll();
    for (let i = 0; i < configValues.length; i++) {
        await config.update({value: configDefaults[configValues[i].key]}, {where: {key: configValues[i].key}});
    }

    await node.destroy({where: {}});
    await recommendations.destroy({where: {}});
    await integration.destroy({where: {}});

    timer.stopTimer();
    timer.startTimer(configDefaults.cron);

    interfaces.requestInterfaces();

    return true;
}
