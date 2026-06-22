#ifndef RUNNER_NATIVE_CONTEXT_PLUGIN_H_
#define RUNNER_NATIVE_CONTEXT_PLUGIN_H_

#include <flutter/event_channel.h>
#include <flutter/event_sink.h>
#include <flutter/event_stream_handler.h>
#include <flutter/flutter_engine.h>
#include <flutter/method_channel.h>
#include <flutter/standard_method_codec.h>

#include <memory>
#include <mutex>
#include <string>
#include <thread>

// Plugin that exposes the foreground window info to Dart via MethodChannel
// and EventChannel.
class NativeContextPlugin {
 public:
  static void RegisterWithEngine(flutter::FlutterEngine* engine);

 private:
  NativeContextPlugin(flutter::FlutterEngine* engine);
  ~NativeContextPlugin();

  // MethodChannel handler
  void HandleMethodCall(
      const flutter::MethodCall<flutter::EncodableValue>& call,
      std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);

  // Captures the current foreground window info and returns it as an
  // EncodableMap.
  flutter::EncodableMap CaptureForegroundContext();

  // Polling thread used when the EventChannel has listeners.
  void StartPolling();
  void StopPolling();

  std::unique_ptr<flutter::MethodChannel<flutter::EncodableValue>>
      method_channel_;
  std::unique_ptr<flutter::EventChannel<flutter::EncodableValue>>
      event_channel_;

  // Guarded by mutex_
  std::unique_ptr<flutter::EventSink<flutter::EncodableValue>> event_sink_;
  std::mutex mutex_;

  std::thread poll_thread_;
  bool polling_ = false;
};

#endif  // RUNNER_NATIVE_CONTEXT_PLUGIN_H_
