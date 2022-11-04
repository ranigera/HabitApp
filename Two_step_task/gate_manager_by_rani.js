// -----------------------------------------------------------------------------------------
// 1) THESE ARE FUNCTION WAS DESIGNED TO MAKE SURE PARTICIPANTS OPEN IT ON THEIR COMPUTER AND NOT SMARTPHONE.
// 2) ALSO MAKES SURE THAT THERE IS A HASH URL VARIABLE (which is used to indicate subject number/code).
// 3) Also delete caches (in case there are on this device from this domain).
// -----------------------------------------------------------------------------------------

// get mobile func OS function:
function getMobileOperatingSystem() { // adapted by Rani from https://stackoverflow.com/questions/21741841/detecting-ios-android-operating-system
    var userAgent = navigator.userAgent || navigator.vendor || window.opera;
    // Windows Phone must come first because its UA also contains "Android"
    if (/windows phone/i.test(userAgent)) {
        return "Windows Phone";
    }
    if (/android/i.test(userAgent)) {
        return "Android";
    }
    // iOS detection from: http://stackoverflow.com/a/9039885/177710
    if (/iPad|iPhone|iPod/.test(userAgent) && !window.MSStream) {
        return "iOS";
    }
    return "unknown";
}

function getMobileBrowser() { // adapted by Rani from https://stackoverflow.com/questions/62409889/how-to-detect-browser-for-chrome
    const agent = window.navigator.userAgent.toLowerCase()
    // check which browser
    switch (true) {
        case agent.indexOf("edge") > -1: return "MS Edge (EdgeHtml)";
        case agent.indexOf("edg") > -1: return "MS Edge Chromium";
        case agent.indexOf("opr") > -1 && !!window.opr: return "opera";
        case agent.indexOf("samsung") > -1: return "samsungInternet";
        case agent.indexOf("chrome") > -1 && !!window.chrome: return "chrome";
        case agent.indexOf("trident") > -1: return "Internet Explorer";
        case agent.indexOf("firefox") > -1: return "firefox";
        case agent.indexOf("safari") > -1: return "safari";
        default: return "other";
    }
};

function checkIfTablet() { // adapted by rani from https://stackoverflow.com/questions/50195475/detect-if-device-is-tablet/53518181
    const userAgent = navigator.userAgent.toLowerCase();
    const isTablet = /(ipad|tablet|(android(?!.*mobile))|(windows(?!.*phone)(.*touch))|kindle|playbook|silk|(puffin(?!.*(IP|AP|WP))))/.test(userAgent);
    return isTablet
}

// check relevant stuff:
// ********************************************************

// get device type:
var mobileOS = getMobileOperatingSystem();
// get device browser:
var browser = getMobileBrowser()
// check if tablet:
var isTablet = checkIfTablet()
// Check that the url is valid:
if (isTablet || mobileOS === 'iOS' || mobileOS === 'Android') {
    location.replace('./not_on_smartphone.html')
} else {
    if (!window.location.hash.substr(1)) {
        location.replace('./link_incomplete.html')
    } else { // everything is good, clear caches and run the tasks:
        caches.keys().then(function (keyList) {
            return Promise.all(keyList.map(function (key) {
                return caches.delete(key);
            }));
        })
        console.log('>> cache storage deleted');
    }
}

