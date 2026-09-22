import 'dart:io';

void main() async {
  final apkFile = File('C:\\Users\\deepak.kumar\\Downloads\\ChronoMed.apk');
  final server = await HttpServer.bind(InternetAddress.anyIPv4, 8081);

  print('=' * 60);
  print('📲 CHRONOMED MOBILE DOWNLOAD SERVER IS LIVE!');
  print('👉 On your phone browser, open: http://192.168.29.33:8081');
  print('=' * 60);

  await for (HttpRequest request in server) {
    final path = request.uri.path;

    if (path == '/ChronoMed.apk' || path == '/download') {
      if (await apkFile.exists()) {
        request.response.headers
          ..contentType = ContentType('application', 'vnd.android.package-archive')
          ..set('Content-Disposition', 'attachment; filename="ChronoMed.apk"')
          ..set('Content-Length', (await apkFile.length()).toString());
        await apkFile.openRead().pipe(request.response);
      } else {
        request.response
          ..statusCode = HttpStatus.notFound
          ..write('APK file not found.')
          ..close();
      }
    } else {
      // Landing page with one-tap download button
      final html = '''
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Download ChronoMed App</title>
  <style>
    * { box-sizing: border-box; margin: 0; padding: 0; }
    body {
      background: #07090E;
      color: #F1F5F9;
      font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif;
      display: flex;
      flex-direction: column;
      align-items: center;
      justify-content: center;
      min-height: 100vh;
      padding: 24px;
      text-align: center;
    }
    .card {
      background: #0F172A;
      border: 1px solid #1E293B;
      border-radius: 24px;
      padding: 32px 24px;
      max-width: 380px;
      width: 100%;
      box-shadow: 0 20px 40px rgba(0,0,0,0.5);
    }
    .icon {
      font-size: 56px;
      margin-bottom: 16px;
    }
    h1 {
      font-size: 24px;
      font-weight: 800;
      color: #22D3EE;
      margin-bottom: 8px;
    }
    p {
      color: #94A3B8;
      font-size: 14px;
      line-height: 1.5;
      margin-bottom: 24px;
    }
    .badge {
      display: inline-block;
      background: rgba(16, 185, 129, 0.15);
      color: #10B981;
      border: 1px solid rgba(16, 185, 129, 0.3);
      padding: 4px 12px;
      border-radius: 999px;
      font-size: 12px;
      font-weight: 700;
      margin-bottom: 24px;
    }
    .btn {
      display: block;
      width: 100%;
      background: linear-gradient(135deg, #10B981, #059669);
      color: white;
      text-decoration: none;
      font-weight: 700;
      font-size: 16px;
      padding: 16px;
      border-radius: 14px;
      box-shadow: 0 4px 14px rgba(16, 185, 129, 0.4);
      transition: transform 0.2s;
    }
    .btn:active {
      transform: scale(0.98);
    }
    .steps {
      margin-top: 24px;
      text-align: left;
      background: #0A0E17;
      border-radius: 12px;
      padding: 16px;
      font-size: 13px;
      color: #94A3B8;
      line-height: 1.6;
    }
    .steps b { color: #F1F5F9; }
  </style>
</head>
<body>
  <div class="card">
    <div class="icon">💊</div>
    <h1>ChronoMed Android</h1>
    <p>Clinical-Grade Medication Choreographer</p>
    <div class="badge">v1.0.0 · Release Build (20 MB)</div>
    
    <a href="/download" class="btn">📥 Download APK Now</a>

    <div class="steps">
      <b>Install Karne Ke Steps:</b><br>
      1. Upar <b>Download APK</b> par tap karein.<br>
      2. Download complete hone par file open karein.<br>
      3. <b>Install</b> par click karein (agar "Unknown sources" allow karne bole to enable kar dein).<br>
      4. App open karein aur use karein!
    </div>
  </div>
</body>
</html>
      ''';
      request.response
        ..headers.contentType = ContentType.html
        ..write(html)
        ..close();
    }
  }
}
