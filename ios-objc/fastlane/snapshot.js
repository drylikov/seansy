#import "SnapshotHelper.js"

var target = UIATarget.localTarget();
var app = target.frontMostApp();
var window = app.mainWindow();
var showtimeCellIndex = 2;

target.delay(10);
captureLocalizedScreenshot("0-Movies");
window.scrollViews()[0].collectionViews()[0].cells()[0].tap();
target.delay(2);
captureLocalizedScreenshot("2-Movie");
app.navigationBar().leftButton().tap();
target.delay(2);
app.tabBar().buttons()[1].tap();
window.scrollViews()[0].tableViews()[0].groups()[0].tap();
target.delay(2);
window.scrollViews()[0].tableViews()[0].cells()[0].collectionViews()[0].cells()[showtimeCellIndex].tap();
target.delay(2);
captureLocalizedScreenshot("1-Showtimes");
window.scrollViews()[0].tableViews()[0].cells()[0].collectionViews()[0].cells()[showtimeCellIndex].touchAndHold();
target.delay(2);
captureLocalizedScreenshot("3-Showtime");
window.buttons()[2].tap();
target.delay(1);
app.tabBar().buttons()[3].tap();
target.delay(5);
captureLocalizedScreenshot("4-News");
