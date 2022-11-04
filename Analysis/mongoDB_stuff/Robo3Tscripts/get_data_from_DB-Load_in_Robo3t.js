//db.getCollection('sessions').find({})
//db.getCollection('sessions').find({}).toArray()
//db.getCollection('sessions').find({}).map((x)=>Object.assign(x,new Date(x.log8)-new Date(x.log7)))
var cursor = db.getCollection('sessions').find({}, {});
var firstLine=true
var notCompleted=true
while(cursor.hasNext() || notCompleted) {
    if (firstLine) {
        print('[');
        firstLine=false;
        }
    if (cursor.hasNext()) {
        print(tojson(cursor.next()));
        if (cursor.hasNext()) {
            print(',');
        }
    } else {
      print(']');
      break;
    }
}
