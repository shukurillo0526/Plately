// Always use the stub implementation (no native DLL needed).
// The conditional `if (dart.library.ffi)` in the original package
// would select the FFI version, which requires a native DLL we don't have.
export 'src/details.dart';
export 'src/msix/stub.dart';
export 'src/plugin/stub.dart';
