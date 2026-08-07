import os
import subprocess

def optimize_images():
    assets_dirs = ['assets/images', 'hotel_assets/images', 'hotel_assets/pdf']
    print("Starting asset optimization scan...")
    
    jpeg_count = 0
    png_count = 0
    pdf_count = 0
    total_saved = 0
    
    for assets_dir in assets_dirs:
        if not os.path.exists(assets_dir):
            continue
        for root, dirs, files in os.walk(assets_dir):
            for file in files:
                filepath = os.path.join(root, file)
                ext = os.path.splitext(file)[1].lower()
                
                if ext in ['.jpg', '.jpeg']:
                    original_size = os.path.getsize(filepath)
                    # Optimize JPEGs over 200KB
                    if original_size > 200 * 1024:
                        print(f"Optimizing JPEG: {filepath} ({original_size / 1024:.1f} KB)")
                        try:
                            # Resize to max 1920, strip EXIF metadata, quality 75
                            subprocess.run([
                                'magick', filepath,
                                '-resize', '1920x1920>',
                                '-strip',
                                '-quality', '75',
                                filepath
                            ], check=True)
                            new_size = os.path.getsize(filepath)
                            saved = original_size - new_size
                            total_saved += saved
                            jpeg_count += 1
                            print(f"  -> Done: {new_size / 1024:.1f} KB (Saved {saved / 1024:.1f} KB)")
                        except Exception as e:
                            print(f"  -> Error optimizing {filepath}: {e}")
                            
                elif ext == '.png':
                    original_size = os.path.getsize(filepath)
                    # Optimize PNGs over 500KB (e.g. maps)
                    if original_size > 500 * 1024:
                        print(f"Optimizing PNG: {filepath} ({original_size / 1024:.1f} KB)")
                        try:
                            # Index to 256 colors to preserve transparency and strip metadata
                            subprocess.run([
                                'magick', filepath,
                                '-colors', '256',
                                '-strip',
                                filepath
                            ], check=True)
                            new_size = os.path.getsize(filepath)
                            saved = original_size - new_size
                            total_saved += saved
                            png_count += 1
                            print(f"  -> Done: {new_size / 1024:.1f} KB (Saved {saved / 1024:.1f} KB)")
                        except Exception as e:
                            print(f"  -> Error optimizing {filepath}: {e}")

                elif ext == '.pdf':
                    original_size = os.path.getsize(filepath)
                    # Optimize PDFs over 2MB
                    if original_size > 2 * 1024 * 1024:
                        print(f"Optimizing PDF: {filepath} ({original_size / (1024*1024):.1f} MB)")
                        tmp_pdf = filepath + ".tmp"
                        try:
                            subprocess.run([
                                'gs', '-sDEVICE=pdfwrite', '-dCompatibilityLevel=1.4',
                                '-dPDFSETTINGS=/ebook', '-dNOPAUSE', '-dQUIET', '-dBATCH',
                                f'-sOutputFile={tmp_pdf}', filepath
                            ], check=True)
                            new_size = os.path.getsize(tmp_pdf)
                            if new_size < original_size:
                                os.replace(tmp_pdf, filepath)
                                saved = original_size - new_size
                                total_saved += saved
                                pdf_count += 1
                                print(f"  -> Done: {new_size / (1024*1024):.1f} MB (Saved {saved / (1024*1024):.1f} MB)")
                            else:
                                if os.path.exists(tmp_pdf): os.remove(tmp_pdf)
                        except Exception as e:
                            if os.path.exists(tmp_pdf): os.remove(tmp_pdf)
                            print(f"  -> Error optimizing {filepath}: {e}")

    print(f"\nOptimization Complete!")
    print(f"  JPEGs Optimized: {jpeg_count}")
    print(f"  PNGs Optimized: {png_count}")
    print(f"  PDFs Optimized: {pdf_count}")
    print(f"  Total Space Saved: {total_saved / (1024 * 1024):.2f} MB")

if __name__ == '__main__':
    optimize_images()
