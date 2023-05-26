//creation of demo data
import '../model/Passkey.dart';

Passkey testPasskey1 = Passkey(
  relyingPartyId: "www.sample.com",
  relyingPartyName: "sample",
  userId: "",
  username: "testuser",
  displayName: "test user",
);

Passkey testPasskey2 = Passkey(
  relyingPartyId: "www.service.com",
  relyingPartyName: "service",
  userId: "",
  username: "another_user",
  displayName: "another user",
);

List<Passkey> testPasskeysList = [testPasskey1, testPasskey2];
