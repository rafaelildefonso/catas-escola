#include "native_context_plugin.h"

#include <windows.h>
#include <psapi.h>
#include <oleacc.h>

#include <chrono>
#include <codecvt>
#include <locale>
#include <sstream>

#pragma comment(lib, "oleacc.lib")

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

static std::string WideToUtf8(const std::wstring& wide) {
  if (wide.empty()) return {};
  int size = WideCharToMultiByte(CP_UTF8, 0, wide.data(),
                                  static_cast<int>(wide.size()), nullptr, 0,
                                  nullptr, nullptr);
  std::string out(size, '\0');
  WideCharToMultiByte(CP_UTF8, 0, wide.data(),
                      static_cast<int>(wide.size()), &out[0], size, nullptr,
                      nullptr);
  return out;
}

static std::string GetProcessName(HWND hwnd) {
  DWORD pid = 0;
  GetWindowThreadProcessId(hwnd, &pid);
  if (pid == 0) return {};

  HANDLE proc =
      OpenProcess(PROCESS_QUERY_LIMITED_INFORMATION, FALSE, pid);
  if (!proc) return {};

  wchar_t path[MAX_PATH]{};
  DWORD len = MAX_PATH;
  QueryFullProcessImageNameW(proc, 0, path, &len);
  CloseHandle(proc);

  // Extract just the executable name.
  std::wstring full(path);
  auto pos = full.find_last_of(L"\\/");
  if (pos != std::wstring::npos) {
    full = full.substr(pos + 1);
  }
  return WideToUtf8(full);
}

static std::string GetWindowTitle(HWND hwnd) {
  int length = GetWindowTextLengthW(hwnd);
  if (length == 0) return {};
  std::wstring title(length + 1, L'\0');
  GetWindowTextW(hwnd, &title[0], length + 1);
  title.resize(length);
  return WideToUtf8(title);
}

// Try to extract the URL from the address bar of known browsers using
// UI Automation (IAccessible). This is a best-effort heuristic.
static std::string TryGetBrowserUrl(HWND hwnd, const std::string& proc_name) {
  // Only attempt for known browsers.
  bool is_browser = false;
  if (proc_name.find("chrome") != std::string::npos ||
      proc_name.find("msedge") != std::string::npos ||
      proc_name.find("firefox") != std::string::npos ||
      proc_name.find("opera") != std::string::npos ||
      proc_name.find("brave") != std::string::npos) {
    is_browser = true;
  }
  if (!is_browser) return {};

  // Use IAccessible to walk to the address bar.
  IAccessible* pAcc = nullptr;
  HRESULT hr = AccessibleObjectFromWindow(hwnd, OBJID_WINDOW,
                                           IID_IAccessible,
                                           reinterpret_cast<void**>(&pAcc));
  if (FAILED(hr) || !pAcc) return {};

  // For Chromium-based browsers the URL usually lives in a child with
  // ROLE_SYSTEM_TEXT and accName "Address and search bar" or similar.
  // We do a simple BFS up to 2 levels; this keeps it lightweight.
  auto tryExtract = [](IAccessible* acc) -> std::string {
    long childCount = 0;
    acc->get_accChildCount(&childCount);
    if (childCount <= 0) return {};

    // Get children
    long obtained = 0;
    std::vector<VARIANT> children(childCount);
    HRESULT hr2 = AccessibleChildren(acc, 0, childCount, children.data(), &obtained);
    if (FAILED(hr2)) return {};

    for (long i = 0; i < obtained; ++i) {
      if (children[i].vt != VT_DISPATCH) continue;
      IAccessible* child = nullptr;
      children[i].pdispVal->QueryInterface(IID_IAccessible, (void**)&child);
      if (!child) continue;

      VARIANT role;
      VARIANT self;
      self.vt = VT_I4;
      self.lVal = CHILDID_SELF;
      child->get_accRole(self, &role);

      if (role.vt == VT_I4 && role.lVal == ROLE_SYSTEM_TOOLBAR) {
        // Recurse into toolbar children looking for the text field.
        long tbCount = 0;
        child->get_accChildCount(&tbCount);
        std::vector<VARIANT> tbChildren(tbCount);
        long tbObtained = 0;
        AccessibleChildren(child, 0, tbCount, tbChildren.data(), &tbObtained);
        for (long j = 0; j < tbObtained; ++j) {
          if (tbChildren[j].vt != VT_DISPATCH) continue;
          IAccessible* tbChild = nullptr;
          tbChildren[j].pdispVal->QueryInterface(IID_IAccessible, (void**)&tbChild);
          if (!tbChild) continue;

          VARIANT tbRole;
          tbChild->get_accRole(self, &tbRole);
          if (tbRole.vt == VT_I4 &&
              (tbRole.lVal == ROLE_SYSTEM_TEXT || tbRole.lVal == ROLE_SYSTEM_COMBOBOX)) {
            BSTR val = nullptr;
            tbChild->get_accValue(self, &val);
            if (val) {
              std::wstring ws(val, SysStringLen(val));
              SysFreeString(val);
              tbChild->Release();
              // cleanup remaining
              for (long k = j + 1; k < tbObtained; ++k) {
                if (tbChildren[k].vt == VT_DISPATCH) tbChildren[k].pdispVal->Release();
              }
              for (long k = i + 1; k < obtained; ++k) {
                if (children[k].vt == VT_DISPATCH) children[k].pdispVal->Release();
              }
              child->Release();
              return WideToUtf8(ws);
            }
            tbChild->Release();
          } else {
            tbChild->Release();
          }
        }
      }
      child->Release();
    }
    return {};
  };

  std::string url = tryExtract(pAcc);
  pAcc->Release();
  return url;
}

static std::string Iso8601Now() {
  auto now = std::chrono::system_clock::now();
  auto time = std::chrono::system_clock::to_time_t(now);
  std::tm tm{};
  gmtime_s(&tm, &time);
  char buf[64];
  std::strftime(buf, sizeof(buf), "%Y-%m-%dT%H:%M:%SZ", &tm);
  return buf;
}

// ---------------------------------------------------------------------------
// Plugin implementation
// ---------------------------------------------------------------------------

void NativeContextPlugin::RegisterWithEngine(flutter::FlutterEngine* engine) {
  auto* plugin = new NativeContextPlugin(engine);
  // prevent unused-variable warning
  (void)plugin;
}

NativeContextPlugin::NativeContextPlugin(flutter::FlutterEngine* engine) {
  auto& codec = flutter::StandardMethodCodec::GetInstance();

  // MethodChannel ---------------------------------------------------------
  method_channel_ = std::make_unique<flutter::MethodChannel<flutter::EncodableValue>>(
      engine->messenger(), "com.catas/native_context", &codec);

  method_channel_->SetMethodCallHandler(
      [this](const auto& call, auto result) {
        HandleMethodCall(call, std::move(result));
      });

  // EventChannel ----------------------------------------------------------
  event_channel_ = std::make_unique<flutter::EventChannel<flutter::EncodableValue>>(
      engine->messenger(), "com.catas/native_context_stream", &codec);

  auto handler = std::make_unique<flutter::StreamHandlerFunctions<flutter::EncodableValue>>(
      // OnListen
      [this](const flutter::EncodableValue* /*arguments*/,
             std::unique_ptr<flutter::EventSink<flutter::EncodableValue>>&& sink)
          -> std::unique_ptr<flutter::StreamHandlerError<flutter::EncodableValue>> {
        {
          std::lock_guard<std::mutex> lock(mutex_);
          event_sink_ = std::move(sink);
        }
        StartPolling();
        return nullptr;
      },
      // OnCancel
      [this](const flutter::EncodableValue* /*arguments*/)
          -> std::unique_ptr<flutter::StreamHandlerError<flutter::EncodableValue>> {
        StopPolling();
        {
          std::lock_guard<std::mutex> lock(mutex_);
          event_sink_.reset();
        }
        return nullptr;
      });

  event_channel_->SetStreamHandler(std::move(handler));
}

NativeContextPlugin::~NativeContextPlugin() {
  StopPolling();
}

void NativeContextPlugin::HandleMethodCall(
    const flutter::MethodCall<flutter::EncodableValue>& call,
    std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {
  if (call.method_name() == "getCurrentContext") {
    auto ctx = CaptureForegroundContext();
    result->Success(flutter::EncodableValue(ctx));
  } else if (call.method_name() == "startContextStream") {
    // Stream is managed by EventChannel; this is a no-op on Windows.
    result->Success();
  } else if (call.method_name() == "stopContextStream") {
    result->Success();
  } else {
    result->NotImplemented();
  }
}

flutter::EncodableMap NativeContextPlugin::CaptureForegroundContext() {
  flutter::EncodableMap map;

  HWND fg = GetForegroundWindow();
  if (!fg) {
    map[flutter::EncodableValue("capturedAt")] =
        flutter::EncodableValue(Iso8601Now());
    return map;
  }

  std::string proc = GetProcessName(fg);
  std::string title = GetWindowTitle(fg);
  std::string url = TryGetBrowserUrl(fg, proc);

  map[flutter::EncodableValue("foregroundAppName")] =
      flutter::EncodableValue(title);
  map[flutter::EncodableValue("foregroundAppId")] =
      flutter::EncodableValue(proc);
  if (!url.empty()) {
    map[flutter::EncodableValue("browserUrl")] =
        flutter::EncodableValue(url);
  }
  map[flutter::EncodableValue("capturedAt")] =
      flutter::EncodableValue(Iso8601Now());

  return map;
}

void NativeContextPlugin::StartPolling() {
  if (polling_) return;
  polling_ = true;
  poll_thread_ = std::thread([this]() {
    while (polling_) {
      auto ctx = CaptureForegroundContext();
      {
        std::lock_guard<std::mutex> lock(mutex_);
        if (event_sink_) {
          event_sink_->Success(flutter::EncodableValue(ctx));
        }
      }
      // Poll every 2 seconds to keep CPU usage low.
      for (int i = 0; i < 20 && polling_; ++i) {
        Sleep(100);
      }
    }
  });
}

void NativeContextPlugin::StopPolling() {
  polling_ = false;
  if (poll_thread_.joinable()) {
    poll_thread_.join();
  }
}
