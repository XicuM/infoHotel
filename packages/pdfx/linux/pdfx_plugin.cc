#include "include/pdfx/pdfx_plugin.h"

#include <flutter_linux/flutter_linux.h>
#include <gtk/gtk.h>
#include <sys/types.h>
#include <unistd.h>
#include <limits.h>
#include <libgen.h>

#include <iostream>
#include <string>
#include <vector>
#include <cstring>

#include "pdfx.h"

// Define method names matching Dart side
const char kOpenDocumentDataMethod[] = "open.document.data";
const char kOpenDocumentFileMethod[] = "open.document.file";
const char kOpenDocumentAssetMethod[] = "open.document.asset";
const char kOpenPageMethod[] = "open.page";
const char kCloseDocumentMethod[] = "close.document";
const char kClosePageMethod[] = "close.page";
const char kRenderMethod[] = "render";

std::string get_executable_dir() {
    char result[PATH_MAX];
    ssize_t count = readlink("/proc/self/exe", result, PATH_MAX);
    if (count != -1) {
        std::string path(result, count);
        size_t last_slash = path.find_last_of("/");
        if (last_slash != std::string::npos) {
            return path.substr(0, last_slash);
        }
    }
    return "";
}

static void method_call_handler(FlMethodChannel* channel, FlMethodCall* method_call, gpointer user_data) {
  const gchar* method = fl_method_call_get_name(method_call);
  FlValue* arguments = fl_method_call_get_args(method_call);

  if (strcmp(method, kOpenDocumentAssetMethod) == 0) {
    if (fl_value_get_type(arguments) != FL_VALUE_TYPE_STRING) {
      fl_method_call_respond(method_call, FL_METHOD_RESPONSE(fl_method_error_response_new("pdfx_exception", "Invalid arguments", nullptr)), nullptr);
      return;
    }
    const char* name = fl_value_get_string(arguments);
    std::string path = get_executable_dir() + "/data/flutter_assets/" + name;

    try {
      std::shared_ptr<pdfx::Document> doc = pdfx::openDocument(path);
      g_autoptr(FlValue) result = fl_value_new_map();
      fl_value_set_string_take(result, "id", fl_value_new_string(doc->id.c_str()));
      fl_value_set_string_take(result, "pagesCount", fl_value_new_int(doc->getPageCount()));
      fl_method_call_respond(method_call, FL_METHOD_RESPONSE(fl_method_success_response_new(result)), nullptr);
    } catch (std::exception& e) {
      fl_method_call_respond(method_call, FL_METHOD_RESPONSE(fl_method_error_response_new("pdfx_exception", e.what(), nullptr)), nullptr);
    }
  }

  else if (strcmp(method, kOpenDocumentFileMethod) == 0) {
    if (fl_value_get_type(arguments) != FL_VALUE_TYPE_STRING) {
      fl_method_call_respond(method_call, FL_METHOD_RESPONSE(fl_method_error_response_new("pdfx_exception", "Invalid arguments", nullptr)), nullptr);
      return;
    }
    const char* path = fl_value_get_string(arguments);

    try {
      std::shared_ptr<pdfx::Document> doc = pdfx::openDocument(path);
      g_autoptr(FlValue) result = fl_value_new_map();
      fl_value_set_string_take(result, "id", fl_value_new_string(doc->id.c_str()));
      fl_value_set_string_take(result, "pagesCount", fl_value_new_int(doc->getPageCount()));
      fl_method_call_respond(method_call, FL_METHOD_RESPONSE(fl_method_success_response_new(result)), nullptr);
    } catch (std::exception& e) {
      fl_method_call_respond(method_call, FL_METHOD_RESPONSE(fl_method_error_response_new("pdfx_exception", e.what(), nullptr)), nullptr);
    }
  }

  else if (strcmp(method, kOpenDocumentDataMethod) == 0) {
    if (fl_value_get_type(arguments) != FL_VALUE_TYPE_UINT8_LIST) {
      fl_method_call_respond(method_call, FL_METHOD_RESPONSE(fl_method_error_response_new("pdfx_exception", "Invalid arguments", nullptr)), nullptr);
      return;
    }
    const uint8_t* bytes = fl_value_get_uint8_list(arguments);
    size_t length = fl_value_get_length(arguments);
    std::vector<uint8_t> data(bytes, bytes + length);

    try {
      std::shared_ptr<pdfx::Document> doc = pdfx::openDocument(data);
      g_autoptr(FlValue) result = fl_value_new_map();
      fl_value_set_string_take(result, "id", fl_value_new_string(doc->id.c_str()));
      fl_value_set_string_take(result, "pagesCount", fl_value_new_int(doc->getPageCount()));
      fl_method_call_respond(method_call, FL_METHOD_RESPONSE(fl_method_success_response_new(result)), nullptr);
    } catch (std::exception& e) {
      fl_method_call_respond(method_call, FL_METHOD_RESPONSE(fl_method_error_response_new("pdfx_exception", e.what(), nullptr)), nullptr);
    }
  }

  else if (strcmp(method, kCloseDocumentMethod) == 0) {
    if (fl_value_get_type(arguments) != FL_VALUE_TYPE_STRING) {
      fl_method_call_respond(method_call, FL_METHOD_RESPONSE(fl_method_error_response_new("pdfx_exception", "Invalid arguments", nullptr)), nullptr);
      return;
    }
    const char* id = fl_value_get_string(arguments);
    pdfx::closeDocument(id);
    fl_method_call_respond(method_call, FL_METHOD_RESPONSE(fl_method_success_response_new(nullptr)), nullptr);
  }

  else if (strcmp(method, kOpenPageMethod) == 0) {
    if (fl_value_get_type(arguments) != FL_VALUE_TYPE_MAP) {
      fl_method_call_respond(method_call, FL_METHOD_RESPONSE(fl_method_error_response_new("pdfx_exception", "Invalid arguments", nullptr)), nullptr);
      return;
    }
    FlValue* doc_id_val = fl_value_lookup_string(arguments, "documentId");
    FlValue* page_val = fl_value_lookup_string(arguments, "page");

    if (doc_id_val == nullptr || page_val == nullptr) {
      fl_method_call_respond(method_call, FL_METHOD_RESPONSE(fl_method_error_response_new("pdfx_exception", "documentId and page are required", nullptr)), nullptr);
      return;
    }

    const char* docId = fl_value_get_string(doc_id_val);
    int pageIndex = fl_value_get_int(page_val) - 1;

    try {
      std::shared_ptr<pdfx::Page> page = pdfx::openPage(docId, pageIndex);
      pdfx::PageDetails details = page->getDetails();

      g_autoptr(FlValue) result = fl_value_new_map();
      fl_value_set_string_take(result, "id", fl_value_new_string(page->id.c_str()));
      fl_value_set_string_take(result, "width", fl_value_new_int(details.width));
      fl_value_set_string_take(result, "height", fl_value_new_int(details.height));
      fl_method_call_respond(method_call, FL_METHOD_RESPONSE(fl_method_success_response_new(result)), nullptr);
    } catch (std::exception& e) {
      fl_method_call_respond(method_call, FL_METHOD_RESPONSE(fl_method_error_response_new("pdfx_exception", e.what(), nullptr)), nullptr);
    }
  }

  else if (strcmp(method, kClosePageMethod) == 0) {
    if (fl_value_get_type(arguments) != FL_VALUE_TYPE_STRING) {
      fl_method_call_respond(method_call, FL_METHOD_RESPONSE(fl_method_error_response_new("pdfx_exception", "Invalid arguments", nullptr)), nullptr);
      return;
    }
    const char* id = fl_value_get_string(arguments);
    pdfx::closePage(id);
    fl_method_call_respond(method_call, FL_METHOD_RESPONSE(fl_method_success_response_new(nullptr)), nullptr);
  }

  else if (strcmp(method, kRenderMethod) == 0) {
    if (fl_value_get_type(arguments) != FL_VALUE_TYPE_MAP) {
      fl_method_call_respond(method_call, FL_METHOD_RESPONSE(fl_method_error_response_new("pdfx_exception", "Invalid arguments", nullptr)), nullptr);
      return;
    }
    FlValue* page_id_val = fl_value_lookup_string(arguments, "pageId");
    FlValue* w_val = fl_value_lookup_string(arguments, "width");
    FlValue* h_val = fl_value_lookup_string(arguments, "height");
    FlValue* bg_val = fl_value_lookup_string(arguments, "backgroundColor");
    FlValue* fmt_val = fl_value_lookup_string(arguments, "format");
    FlValue* crop_val = fl_value_lookup_string(arguments, "crop");

    if (!page_id_val || !w_val || !h_val || !bg_val || !fmt_val || !crop_val) {
      fl_method_call_respond(method_call, FL_METHOD_RESPONSE(fl_method_error_response_new("pdfx_exception", "Missing parameters for render", nullptr)), nullptr);
      return;
    }

    const char* pageId = fl_value_get_string(page_id_val);
    int width = fl_value_get_int(w_val);
    int height = fl_value_get_int(h_val);
    const char* background = fl_value_get_string(bg_val);
    int format_int = fl_value_get_int(fmt_val);
    bool crop = fl_value_get_bool(crop_val);

    pdfx::ImageFormat format;
    if (format_int == 0) format = pdfx::JPEG;
    else if (format_int == 1) format = pdfx::PNG;
    else {
      fl_method_call_respond(method_call, FL_METHOD_RESPONSE(fl_method_error_response_new("pdfx_exception", "Unsupported format", nullptr)), nullptr);
      return;
    }

    pdfx::CropDetails* cropDetails = nullptr;
    if (crop) {
      cropDetails = new pdfx::CropDetails();
      cropDetails->crop_x = fl_value_get_int(fl_value_lookup_string(arguments, "crop_x"));
      cropDetails->crop_y = fl_value_get_int(fl_value_lookup_string(arguments, "crop_y"));
      cropDetails->crop_width = fl_value_get_int(fl_value_lookup_string(arguments, "crop_width"));
      cropDetails->crop_height = fl_value_get_int(fl_value_lookup_string(arguments, "crop_height"));
    }

    try {
      pdfx::PageRender render = pdfx::renderPage(pageId, width, height, format, background, cropDetails);
      g_autoptr(FlValue) result = fl_value_new_map();
      fl_value_set_string_take(result, "data", fl_value_new_uint8_list(render.data.data(), render.data.size()));
      fl_value_set_string_take(result, "width", fl_value_new_int(render.width));
      fl_value_set_string_take(result, "height", fl_value_new_int(render.height));
      fl_method_call_respond(method_call, FL_METHOD_RESPONSE(fl_method_success_response_new(result)), nullptr);
    } catch (std::exception& e) {
      fl_method_call_respond(method_call, FL_METHOD_RESPONSE(fl_method_error_response_new("pdfx_exception", e.what(), nullptr)), nullptr);
    }

    delete cropDetails;
  }

  else {
    fl_method_call_respond(method_call, FL_METHOD_RESPONSE(fl_method_not_implemented_response_new()), nullptr);
  }
}

void pdfx_plugin_register_with_registrar(FlPluginRegistrar* registrar) {
  FlBinaryMessenger* messenger = fl_plugin_registrar_get_messenger(registrar);
  g_autoptr(FlStandardMethodCodec) codec = fl_standard_method_codec_new();
  g_autoptr(FlMethodChannel) channel = fl_method_channel_new(messenger, "io.scer.pdf_renderer", FL_METHOD_CODEC(codec));

  fl_method_channel_set_method_call_handler(channel, method_call_handler, nullptr, nullptr);
}
