class Endpoints {
  static const urlAllCats = "https://api.thecatapi.com/v1/breeds";

  static const urlForGetImageCat = "https://api.thecatapi.com/v1/images/";

  /// The key used to be a copy-pasted literal in two places in the datasource.
  /// Hoisting it here makes Phase 4's `--dart-define-from-file` migration a
  /// one-line change.
  ///
  /// Note: the header name is `api-key`, but TheCatAPI expects `x-api-key`, so
  /// these requests were never authenticated. `/breeds` and `/images/{id}` work
  /// without a key, so the app has always been on the anonymous tier. Both are
  /// fixed in Phase 4, along with moving the secret out of the source.
  static const authHeader = <String, String>{
    "api-key": "bda53789-d59e-46cd-9bc4-2936630fde39",
  };
}
