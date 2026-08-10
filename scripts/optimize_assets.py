import os
import sys
import subprocess

def optimize_single_file(filepath):
    """Optimizes a single image or PDF file in-place if it exceeds target size thresholds."""
    if not os.path.exists(filepath):
        return 0

    ext = os.path.splitext(filepath)[1].lower()
    original_size = os.path.getsize(filepath)
    saved = 0

    if ext in ['.jpg', '.jpeg']:
        if original_size > 150 * 1024:
            print(f"Optimizing JPEG: {filepath} ({original_size / 1024:.1f} KB)")
            # Try ImageMagick 7 (magick) or 6 (convert), fallback to PIL if available
            success = False
            for cmd in ['magick', 'convert']:
                try:
                    subprocess.run([
                        cmd, filepath,
                        '-resize', '1920x1920>',
                        '-strip',
                        '-quality', '75',
                        filepath
                    ], check=True, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
                    success = True
                    break
                except Exception:
                    pass

            if not success:
                try:
                    from PIL import Image
                    with Image.open(filepath) as img:
                        img.thumbnail((1920, 1920))
                        img.save(filepath, 'JPEG', quality=75, optimize=True)
                    success = True
                except Exception as e:
                    print(f"  -> Unable to optimize JPEG {filepath}: {e}")

            if success:
                new_size = os.path.getsize(filepath)
                saved = max(0, original_size - new_size)
                print(f"  -> Done: {new_size / 1024:.1f} KB (Saved {saved / 1024:.1f} KB)")

    elif ext == '.png':
        if original_size > 300 * 1024:
            print(f"Optimizing PNG: {filepath} ({original_size / 1024:.1f} KB)")
            success = False
            for cmd in ['magick', 'convert']:
                try:
                    subprocess.run([
                        cmd, filepath,
                        '-colors', '256',
                        '-strip',
                        filepath
                    ], check=True, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
                    success = True
                    break
                except Exception:
                    pass

            if not success:
                try:
                    from PIL import Image
                    with Image.open(filepath) as img:
                        img.save(filepath, 'PNG', optimize=True)
                    success = True
                except Exception as e:
                    print(f"  -> Unable to optimize PNG {filepath}: {e}")

            if success:
                new_size = os.path.getsize(filepath)
                saved = max(0, original_size - new_size)
                print(f"  -> Done: {new_size / 1024:.1f} KB (Saved {saved / 1024:.1f} KB)")

    elif ext == '.pdf':
        if original_size > 1.5 * 1024 * 1024:
            print(f"Optimizing PDF: {filepath} ({original_size / (1024*1024):.1f} MB)")
            tmp_pdf = filepath + ".tmp"
            try:
                subprocess.run([
                    'gs', '-sDEVICE=pdfwrite', '-dCompatibilityLevel=1.4',
                    '-dPDFSETTINGS=/ebook', '-dNOPAUSE', '-dQUIET', '-dBATCH',
                    f'-sOutputFile={tmp_pdf}', filepath
                ], check=True, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
                new_size = os.path.getsize(tmp_pdf)
                if new_size < original_size:
                    os.replace(tmp_pdf, filepath)
                    saved = original_size - new_size
                    print(f"  -> Done: {new_size / (1024*1024):.1f} MB (Saved {saved / (1024*1024):.1f} MB)")
                else:
                    if os.path.exists(tmp_pdf): os.remove(tmp_pdf)
            except Exception as e:
                if os.path.exists(tmp_pdf): os.remove(tmp_pdf)
                print(f"  -> Error optimizing PDF {filepath}: {e}")

    return saved

def optimize_images():
    assets_dirs = ['assets/images', 'hotel_assets/images', 'hotel_assets/pdf', 'hotel_assets']
    print("Starting asset optimization scan...")
    
    jpeg_count = 0
    png_count = 0
    pdf_count = 0
    total_saved = 0
    processed_files = set()
    
    for assets_dir in assets_dirs:
        if not os.path.exists(assets_dir):
            continue
        for root, dirs, files in os.walk(assets_dir):
            for file in files:
                filepath = os.path.abspath(os.path.join(root, file))
                if filepath in processed_files:
                    continue
                processed_files.add(filepath)

                ext = os.path.splitext(file)[1].lower()
                if ext in ['.jpg', '.jpeg', '.png', '.pdf']:
                    saved = optimize_single_file(filepath)
                    if saved > 0:
                        total_saved += saved
                        if ext in ['.jpg', '.jpeg']:
                            jpeg_count += 1
                        elif ext == '.png':
                            png_count += 1
                        elif ext == '.pdf':
                            pdf_count += 1

    print(f"\nOptimization Complete!")
    print(f"  JPEGs Optimized: {jpeg_count}")
    print(f"  PNGs Optimized: {png_count}")
    print(f"  PDFs Optimized: {pdf_count}")
    print(f"  Total Space Saved: {total_saved / (1024 * 1024):.2f} MB")

if __name__ == '__main__':
    if len(sys.argv) > 1:
        target = sys.argv[1]
        if os.path.isfile(target):
            optimize_single_file(target)
        else:
            optimize_images()
    else:
        optimize_images()
