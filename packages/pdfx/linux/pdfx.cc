#include <fstream>
#include <iostream>
#include <stdexcept>
#include <string>
#include <unordered_map>
#include <cstring>

#include "pdfx.h"

namespace pdfx {

std::unordered_map<std::string, std::shared_ptr<Document>> document_repository;
std::unordered_map<std::string, std::shared_ptr<Page>> page_repository;
int lastId = 0;

std::shared_ptr<Document> openDocument(std::vector<uint8_t> data) {
  if (document_repository.size() == 0) {
    FPDF_LIBRARY_CONFIG config;
    config.version = 2;
    config.m_pUserFontPaths = NULL;
    config.m_pIsolate = NULL;
    config.m_v8EmbedderSlot = 0;
    FPDF_InitLibraryWithConfig(&config);
  }

  lastId++;
  std::string strId = std::to_string(lastId);

  std::shared_ptr<Document> doc = std::make_shared<Document>(data, strId);
  document_repository[strId] = doc;

  return doc;
}

std::shared_ptr<Document> openDocument(std::string name) {
  if (document_repository.size() == 0) {
    FPDF_LIBRARY_CONFIG config;
    config.version = 2;
    config.m_pUserFontPaths = NULL;
    config.m_pIsolate = NULL;
    config.m_v8EmbedderSlot = 0;
    FPDF_InitLibraryWithConfig(&config);
  }

  lastId++;
  std::string strId = std::to_string(lastId);

  std::shared_ptr<Document> doc = std::make_shared<Document>(name, strId);
  document_repository[strId] = doc;

  return doc;
}

void closeDocument(std::string id) {
  document_repository.erase(id);

  if (document_repository.size() == 0) {
    FPDF_DestroyLibrary();
  }
}

std::shared_ptr<Page> openPage(std::string docId, int index) {
  lastId++;
  std::string strId = std::to_string(lastId);

  auto doc = document_repository.find(docId);
  if (doc == document_repository.end()) {
    throw std::invalid_argument("Document is not open");
  }

  std::shared_ptr<Page> page =
      std::make_shared<Page>(doc->second, index, strId);

  page_repository[strId] = page;

  return page;
}

void closePage(std::string id) { page_repository.erase(id); }

PageRender renderPage(std::string id, int width, int height, ImageFormat format,
                      std::string backgroundStr, CropDetails* crop) {
  auto page = page_repository.find(id);
  if (page == page_repository.end()) {
    throw std::invalid_argument("Page does not exist");
  }

  // Get background color
  backgroundStr.erase(0, 1);
  auto background = std::stoul(backgroundStr, nullptr, 16);

  // Render page
  return page->second->render(width, height, format, background, crop);
}

//

Document::Document(std::vector<uint8_t> dataRef, std::string id) : id{id} {
  // Copy data into object to keep it in memory
  data.swap(dataRef);

  document = FPDF_LoadMemDocument64(data.data(), data.size(), nullptr);
  if (!document) {
    throw std::invalid_argument("Document failed to open");
  }
}

Document::Document(std::string file, std::string id) : id{id} {
  std::ifstream fs(file, std::ios::binary | std::ios::ate);
  if (!fs) {
    throw std::invalid_argument("Document failed to open");
  }

  std::streamsize size = fs.tellg();
  fs.seekg(0, std::ios::beg);

  data.resize(size);
  if (!fs.read(reinterpret_cast<char*>(data.data()), size)) {
    throw std::invalid_argument("Failed to read file");
  }

  // Load PDF
  document = FPDF_LoadMemDocument64(data.data(), size, nullptr);
  if (!document) {
    throw std::invalid_argument("Document failed to open");
  }
}

Document::~Document() { FPDF_CloseDocument(document); }

int Document::getPageCount() { return FPDF_GetPageCount(document); }

Page::Page(std::shared_ptr<Document> doc, int index, std::string id) : id(id) {
  page = FPDF_LoadPage(doc->document, index);
  if (!page) {
    throw std::invalid_argument("Page failed to open");
  }
}

Page::~Page() { FPDF_ClosePage(page); }

PageDetails Page::getDetails() {
  int width = static_cast<int>(FPDF_GetPageWidthF(page) + 0.5f);
  int height = static_cast<int>(FPDF_GetPageHeightF(page) + 0.5f);

  return PageDetails(width, height);
}

// Encode raw BGRA to BMP in memory
std::vector<uint8_t> encodeToBmp(const uint8_t* pixels, int width, int height, int stride) {
    #pragma pack(push, 1)
    struct BMPFileHeader {
        uint16_t file_type{0x4D42}; // "BM"
        uint32_t file_size{0};
        uint16_t reserved1{0};
        uint16_t reserved2{0};
        uint32_t offset_data{54};
    };

    struct BMPInfoHeader {
        uint32_t size{40};
        int32_t width{0};
        int32_t height{0}; // Negative for top-down
        uint16_t planes{1};
        uint16_t bit_count{32};
        uint32_t compression{0}; // BI_RGB
        uint32_t size_image{0};
        int32_t x_pixels_per_meter{0};
        int32_t y_pixels_per_meter{0};
        uint32_t colors_used{0};
        uint32_t colors_important{0};
    };
    #pragma pack(pop)

    BMPFileHeader file_header;
    BMPInfoHeader info_header;

    info_header.width = width;
    info_header.height = -height; // negative height means top-down
    info_header.bit_count = 32;
    info_header.size_image = stride * height;

    file_header.file_size = sizeof(BMPFileHeader) + sizeof(BMPInfoHeader) + info_header.size_image;

    std::vector<uint8_t> bmp_data(file_header.file_size);
    std::memcpy(bmp_data.data(), &file_header, sizeof(BMPFileHeader));
    std::memcpy(bmp_data.data() + sizeof(BMPFileHeader), &info_header, sizeof(BMPInfoHeader));

    // Copy rows
    uint8_t* dest_pixels = bmp_data.data() + sizeof(BMPFileHeader) + sizeof(BMPInfoHeader);
    for (int y = 0; y < height; ++y) {
        std::memcpy(dest_pixels + y * stride, pixels + y * stride, stride);
    }

    return bmp_data;
}

PageRender Page::render(int width, int height, ImageFormat format,
                        unsigned long background, CropDetails* crop) {
  int rWidth, rHeight, start_x, size_x, start_y, size_y;
  if (crop == nullptr) {
    rWidth = width;
    rHeight = height;
    start_x = 0;
    size_x = width;
    start_y = 0;
    size_y = height;
  } else {
    rWidth = crop->crop_width;
    rHeight = crop->crop_height;

    start_x = 0 - crop->crop_x;
    size_x = width;
    start_y = 0 - crop->crop_y;
    size_y = height;
  }

  // Create empty bitmap and render page onto it
  auto bitmap = FPDFBitmap_Create(rWidth, rHeight, 0);
  FPDFBitmap_FillRect(bitmap, 0, 0, rWidth, rHeight, background);
  FPDF_RenderPageBitmap(bitmap, page, start_x, start_y, size_x, size_y, 0,
                        FPDF_ANNOT | FPDF_LCD_TEXT);

  // Convert bitmap into BGRA format
  uint8_t* p = static_cast<uint8_t*>(FPDFBitmap_GetBuffer(bitmap));
  auto stride = FPDFBitmap_GetStride(bitmap);

  // Encode to BMP directly
  std::vector<uint8_t> data = encodeToBmp(p, rWidth, rHeight, stride);

  FPDFBitmap_Destroy(bitmap);

  return PageRender(data, rWidth, rHeight);
}
}  // namespace pdfx
