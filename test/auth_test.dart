import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/drive/v3.dart' as drive;

void main() async {
  final g = GoogleSignIn.instance;
  await g.initialize();
  final account = await g.authenticate();
  final auth = account.authentication;
  final authClient = account.authorizationClient;
  final authorization = await authClient.authorizeScopes([drive.DriveApi.driveFileScope]);
  
  final credential = GoogleAuthProvider.credential(
    idToken: auth.idToken,
    accessToken: authorization.accessToken,
  );
  print(credential);
}
