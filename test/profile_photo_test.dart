import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter_test/flutter_test.dart';
import 'package:solar_ops_mobile/profile_ui.dart';

void main() {
  testWidgets('profile photo is cropped to bounded PNG before upload',
      (tester) async {
    await tester.runAsync(() async {
      final recorder = ui.PictureRecorder();
      ui.Canvas(recorder).drawRect(const ui.Rect.fromLTWH(0, 0, 300, 100),
          ui.Paint()..color = const ui.Color(0xff006600));
      final picture = recorder.endRecording();
      final image = await picture.toImage(300, 100);
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      final photo = await smallProfilePhoto(data!.buffer.asUint8List());
      final header = ByteData.sublistView(photo);
      expect(header.getUint32(16), 128);
      expect(header.getUint32(20), 128);
      expect(photo.length, lessThanOrEqualTo(98304));
      image.dispose();
      picture.dispose();
      await expectLater(
          smallProfilePhoto(Uint8List(5 * 1024 * 1024 + 1)), throwsException);
    });
  });
}
