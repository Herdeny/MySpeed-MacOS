// Curated mainland China nodes from macrwfuse/myspeed-cn.
// These are merged with the public provider lists so MySpeed remains useful
// when the upstream discovery endpoints are slow or unavailable.
export const OOKLA_CN_SERVERS = {
    "3633": {name: "上海", sponsor: "上海电信", country: "中国", cc: "CN", distance: 0, host: "222.68.195.2:8080"},
    "5396": {name: "南京", sponsor: "江苏电信 5G", country: "中国", cc: "CN", distance: 0, host: "115.169.22.130:8080"},
    "59386": {name: "杭州", sponsor: "浙江电信", country: "中国", cc: "CN", distance: 0, host: "61.130.56.1:8080"},
    "16204": {name: "苏州", sponsor: "江苏移动 JSQY", country: "中国", cc: "CN", distance: 0, host: "36.156.46.53:8080"},
    "24447": {name: "上海", sponsor: "上海联通 5G", country: "中国", cc: "CN", distance: 0, host: "210.22.155.34:8080"},
    "30852": {name: "昆山", sponsor: "昆山杜克大学", country: "中国", cc: "CN", distance: 0, host: "speedtest.dukekunshan.edu.cn:8080"},
    "36663": {name: "镇江", sponsor: "江苏电信 5G", country: "中国", cc: "CN", distance: 0, host: "5gzhenjiang.speedtest.jsinfo.net:8080"},
    "43752": {name: "北京", sponsor: "北京联通", country: "中国", cc: "CN", distance: 0, host: "beijing.unicomtest.com:8080"},
    "59387": {name: "宁波", sponsor: "浙江电信", country: "中国", cc: "CN", distance: 0, host: "cesu-nb.zjtelecom.com.cn:8080"},
    "17265": {name: "中和", sponsor: "远传电信（台湾）", country: "中国", cc: "CN", distance: 0, host: "fetsz1.seed.net.tw:8080"},
    "73010": {name: "贺兰", sponsor: "Arslan Telecom", country: "中国", cc: "CN", distance: 0, host: "arslantel.online:8080"}
};

export const LIBRE_CN_SERVERS = {
    "cn-edu-zju": {
        id: "cn-edu-zju", name: "教育网 · 浙江大学", country: "中国",
        server: "http://speedtest.zju.edu.cn/", dlURL: "garbage.php", ulURL: "empty.php",
        pingURL: "empty.php", getIpURL: "getIP.php"
    },
    "cn-edu-ustc": {
        id: "cn-edu-ustc", name: "教育网 · 中国科学技术大学", country: "中国",
        server: "https://test.ustc.edu.cn/backend/", dlURL: "garbage.php", ulURL: "empty.php",
        pingURL: "empty.php", getIpURL: "getIP.php"
    },
    "cn-edu-sjtu": {
        id: "cn-edu-sjtu", name: "教育网 · 上海交通大学", country: "中国",
        server: "https://ftp.sjtu.edu.cn/speedtest/backend/", dlURL: "garbage.php", ulURL: "empty.php",
        pingURL: "empty.php", getIpURL: "getIP.php"
    },
    "cn-edu-nju": {
        id: "cn-edu-nju", name: "教育网 · 南京大学", country: "中国",
        server: "https://fs.nju.edu.cn/speed/", dlURL: "garbage.php", ulURL: "empty.php",
        pingURL: "empty.php", getIpURL: "getIP.php"
    },
    "cn-edu-tsinghua": {
        id: "cn-edu-tsinghua", name: "教育网 · 清华大学", country: "中国",
        server: "https://iptv.tsinghua.edu.cn/st/", dlURL: "garbage.php", ulURL: "empty.php",
        pingURL: "empty.php", getIpURL: "getIP.php"
    },
    "cn-edu-whut": {
        id: "cn-edu-whut", name: "教育网 · 武汉理工大学", country: "中国",
        server: "https://219.140.61.101/backend/", dlURL: "garbage.php", ulURL: "empty.php",
        pingURL: "empty.php", getIpURL: "getIP.php"
    },
    "cn-edu-hubei": {
        id: "cn-edu-hubei", name: "教育网 · 湖北节点", country: "中国",
        server: "https://119.36.86.250:81/backend/", dlURL: "garbage.php", ulURL: "empty.php",
        pingURL: "empty.php", getIpURL: "getIP.php"
    },
    "cn-edu-wh": {
        id: "cn-edu-wh", name: "教育网 · 武汉节点", country: "中国",
        server: "http://211.67.53.2/backend/", dlURL: "garbage.php", ulURL: "empty.php",
        pingURL: "empty.php", getIpURL: "getIP.php"
    }
};
