//creation of demo data
import '../model/Passkey.dart';

Passkey testPasskey = Passkey(
  relyingPartyId: "www.sample.com",
  relyingPartyName: "sample",
  userId: "",
  username: "testuser",
  displayName: "test user",
);

List<Passkey> testPasskeysList = [testPasskey];
