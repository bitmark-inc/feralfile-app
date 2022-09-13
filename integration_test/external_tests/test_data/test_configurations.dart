const APPIUM_SERVER_URL = 'http://0.0.0.0:4723/wd/hub/';
Map<String, String> CHROME_MOBILE_BROWSER_PROFILE(String currentDir) => {
      'platformName': 'android',
      'platformVersion': '12',
      'deviceName': "Galaxy A52s 5G",
      'browserName': 'Chrome',
      'automationName': 'UIAutomator2',
      'chromedriverExecutableDir':
          '${currentDir}/integration_test/external_tests/resources/chromedriver',
    };

Map<String, String> AUTONOMY_PROFILE(String currentDir) => {
      'platformName': "Android",
      'platformVersion': "12",
      'deviceName': 'Galaxy S10+',
      'app':
          "${currentDir}/build/app/outputs/flutter-apk/app-inhouse-release.apk",
      'appPackage': "com.bitmark.autonomy_client.inhouse",
      'appActivity': "com.bitmark.autonomy_flutter.MainActivity",
      'automationName': "UiAutomator2"
    };

// const AUTONOMY_PROFILE = {
//   'platformName': "Android",
//   'platformVersion': "11",
//   'deviceName': 'Redmi Note 11S',
//   'app':
//       "/Volumes/Working/repos/autonomy-client/build/app/outputs/flutter-apk/app-inhouse-release.apk",
//   'appPackage': "com.bitmark.autonomy_client.inhouse",
//   'appActivity': "com.bitmark.autonomy_flutter.MainActivity",
//   'automationName': "UiAutomator2"
// };

const METAMASK_PROFILE = {
  "platformName": "Android",
  "platformVersion": "11",
  "deviceName": "Redmi Note 11S",
  "appPackage": "io.metamask",
  "appActivity": "io.metamask.MainActivity",
  "automationName": "UiAutomator2"
};

const METAMASK_APPPACKAGE = "io.metamask";
const AUTONOMY_APPPACKAGE = "com.bitmark.autonomy_client.inhouse";
const CHROME_APPPACKAGE = "com.android.chrome";
