/// App-wide feature flags and runtime configuration.
class AppConfig {
  AppConfig._();

  /// While the backend is not ready, services return data from
  /// `data/services/mock_data.dart`. Set to `false` once [ApiConfig.baseUrl]
  /// points at a live TechStoreAPI to switch every service to real HTTP calls.
  static const bool useMockData = true;

  /// Artificial latency applied to mock service calls so loading states,
  /// spinners and skeletons are exercised exactly as they will be against the
  /// real network. Set to [Duration.zero] to disable.
  static const Duration mockLatency = Duration(milliseconds: 550);

  /// Phone-canvas max width from the design system (`--app-max-width: 430px`).
  /// Used to keep the layout phone-shaped on wide screens (web/tablet).
  static const double appMaxWidth = 430;
}
