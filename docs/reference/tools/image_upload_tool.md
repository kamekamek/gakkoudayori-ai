# Image Upload Tool API Reference

## Overview

The Image Upload Tool handles file uploads to Firebase Storage and returns secure URLs for use in HTML documents. It integrates seamlessly with the HTML Editor Tool to provide drag-and-drop image insertion capabilities.

## Tool Definition

```python
@tool
async def image_upload_tool(
    file: Union[UploadFile, bytes, str],
    file_name: str = None,
    folder: str = "images",
    resize_options: ImageResizeOptions = None,
    metadata: Dict[str, str] = None
) -> ImageUploadResult:
    """
    Upload image to Firebase Storage and return secure URL.
    
    Args:
        file: Image file data (UploadFile, bytes, or base64 string)
        file_name: Custom filename (auto-generated if not provided)
        folder: Storage folder path (default: "images")
        resize_options: Image resizing configuration
        metadata: Additional metadata to store with image
    
    Returns:
        ImageUploadResult: Contains URL, metadata, and upload info
    
    Raises:
        FileTypeError: Unsupported file format
        FileSizeError: File exceeds size limits
        StorageError: Firebase Storage upload failed
        ValidationError: Invalid parameters or file data
    """
```

## Data Models

### ImageUploadResult

```python
@dataclass
class ImageUploadResult:
    """Result returned from Image Upload Tool"""
    
    # Core data
    url: str                     # Public URL of uploaded image
    signed_url: str              # Temporary signed URL (expires in 1 hour)
    storage_path: str            # Full path in Firebase Storage
    
    # File information
    file_name: str               # Final filename in storage
    original_name: str           # Original filename from upload
    file_size_bytes: int         # File size in bytes
    content_type: str            # MIME type (e.g., image/jpeg)
    
    # Image properties
    width: int                   # Image width in pixels
    height: int                  # Image height in pixels
    format: str                  # Image format (JPEG, PNG, WebP, etc.)
    has_transparency: bool       # Whether image has alpha channel
    
    # Processing information
    was_resized: bool            # Whether image was resized
    original_size_bytes: int     # Original file size before processing
    compression_ratio: float     # Compression ratio (0.0-1.0)
    
    # Upload metadata
    upload_timestamp: datetime   # When image was uploaded
    uploader_id: str             # User ID who uploaded the image
    alt_text: str                # Accessibility alt text (if provided)
    tags: List[str]              # Image tags for categorization
    
    # Firebase Storage metadata
    bucket: str                  # Storage bucket name
    generation: str              # Firebase object generation ID
    etag: str                    # Entity tag for caching
```

### ImageResizeOptions

```python
@dataclass
class ImageResizeOptions:
    """Configuration for image resizing"""
    
    max_width: int = 1920         # Maximum width in pixels
    max_height: int = 1080        # Maximum height in pixels
    quality: int = 85             # JPEG quality (0-100)
    format: str = "auto"          # Output format (auto, jpeg, png, webp)
    
    # Advanced options
    maintain_aspect_ratio: bool = True
    upscale_allowed: bool = False
    progressive_jpeg: bool = True
    strip_metadata: bool = True   # Remove EXIF data
    
    # Thumbnail generation
    generate_thumbnail: bool = False
    thumbnail_size: int = 150     # Thumbnail size (square)
```

### UploadConfig

```python
@dataclass
class UploadConfig:
    """Global configuration for image uploads"""
    
    # File size limits
    max_file_size_mb: int = 10
    max_total_storage_mb: int = 500
    
    # Allowed formats
    allowed_formats: List[str] = field(default_factory=lambda: [
        'image/jpeg', 'image/png', 'image/webp', 'image/gif'
    ])
    
    # Storage settings
    storage_bucket: str = "your-project.appspot.com"
    default_folder: str = "newsletter-images"
    
    # Processing options
    auto_optimize: bool = True
    generate_thumbnails: bool = True
    virus_scan_enabled: bool = True
    
    # Access control
    public_readable: bool = True
    signed_url_expires_hours: int = 24
```

## Usage Examples

### Basic Image Upload

```python
from adk_tools import image_upload_tool
from adk_tools.models import ImageResizeOptions

# Upload from file object
with open("school_photo.jpg", "rb") as f:
    result = await image_upload_tool(
        file=f,
        file_name="spring_festival.jpg",
        folder="events/2024"
    )

print(f"Image URL: {result.url}")
print(f"File size: {result.file_size_bytes} bytes")
print(f"Dimensions: {result.width} x {result.height}")
```

### Upload with Resizing

```python
# Optimize image for web display
resize_options = ImageResizeOptions(
    max_width=800,
    max_height=600,
    quality=80,
    format="webp",
    generate_thumbnail=True
)

result = await image_upload_tool(
    file=image_data,
    resize_options=resize_options,
    metadata={"event": "sports_day", "year": "2024"}
)

if result.was_resized:
    print(f"Resized from {result.original_size_bytes} to {result.file_size_bytes} bytes")
    print(f"Compression ratio: {result.compression_ratio:.2f}")
```

### Batch Upload

```python
async def upload_multiple_images(image_files: List[UploadFile]) -> List[ImageUploadResult]:
    """Upload multiple images concurrently"""
    tasks = []
    
    for i, file in enumerate(image_files):
        task = image_upload_tool(
            file=file,
            folder=f"batch_upload_{datetime.now().strftime('%Y%m%d')}",
            resize_options=ImageResizeOptions(max_width=1200, quality=85)
        )
        tasks.append(task)
    
    results = await asyncio.gather(*tasks, return_exceptions=True)
    
    # Filter successful uploads
    successful_uploads = [r for r in results if isinstance(r, ImageUploadResult)]
    
    return successful_uploads

# Usage
uploaded_images = await upload_multiple_images(request.files)
image_urls = [img.url for img in uploaded_images]
```

### Integration with HTML Editor

```python
# This happens automatically when user inserts image in HTML editor
# But you can also programmatically insert images:

async def insert_image_in_html(html: str, image_file: UploadFile, position: str) -> str:
    """Insert uploaded image into HTML at specified position"""
    
    # Upload image first
    upload_result = await image_upload_tool(
        file=image_file,
        resize_options=ImageResizeOptions(max_width=800, quality=85)
    )
    
    # Create image tag with proper attributes
    img_tag = f'''<img 
        src="{upload_result.url}" 
        alt="{upload_result.alt_text or 'Uploaded image'}"
        width="{upload_result.width}"
        height="{upload_result.height}"
        loading="lazy"
    />'''
    
    # Insert into HTML at position
    return html.replace(f'<!-- {position} -->', img_tag)
```

## Error Handling

### Common Exceptions

```python
from adk_tools.exceptions import (
    FileTypeError,
    FileSizeError,
    StorageError,
    ValidationError
)

try:
    result = await image_upload_tool(file=image_data)
except FileTypeError as e:
    print(f"Unsupported file type: {e.content_type}")
    print(f"Allowed types: {e.allowed_types}")
    
except FileSizeError as e:
    print(f"File too large: {e.size_mb}MB (max: {e.max_size_mb}MB)")
    
except StorageError as e:
    print(f"Upload failed: {e.error_code}")
    print(f"Firebase error: {e.firebase_error}")
    
except ValidationError as e:
    print(f"Invalid input: {e.field} - {e.message}")
```

### Retry Logic

```python
import asyncio
from typing import Optional

async def upload_with_retry(
    file: UploadFile,
    max_retries: int = 3,
    retry_delay: float = 1.0
) -> Optional[ImageUploadResult]:
    """Upload image with automatic retry logic"""
    
    for attempt in range(max_retries):
        try:
            return await image_upload_tool(file=file)
            
        except StorageError as e:
            if attempt == max_retries - 1:
                logger.error(f"Upload failed after {max_retries} attempts: {e}")
                return None
            
            # Exponential backoff
            delay = retry_delay * (2 ** attempt)
            logger.warning(f"Upload attempt {attempt + 1} failed, retrying in {delay}s")
            await asyncio.sleep(delay)
            
        except (FileTypeError, FileSizeError, ValidationError):
            # Don't retry validation errors
            return None
    
    return None
```

## Firebase Storage Integration

### Storage Structure

```
gs://your-project.appspot.com/
├── newsletter-images/
│   ├── 2024/
│   │   ├── spring_festival/
│   │   │   ├── IMG_001.webp
│   │   │   └── IMG_002.jpg
│   │   └── sports_day/
│   └── templates/
├── thumbnails/
│   └── 150x150/
└── temp_uploads/
    └── processing/
```

### Security Rules

```javascript
// Firebase Storage security rules
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    // Allow authenticated users to upload images
    match /newsletter-images/{allPaths=**} {
      allow read: if true;  // Public read access
      allow write: if request.auth != null 
                   && resource.size < 10 * 1024 * 1024  // 10MB limit
                   && request.resource.contentType.matches('image/.*');
    }
    
    // Thumbnails are auto-generated, read-only
    match /thumbnails/{allPaths=**} {
      allow read: if true;
      allow write: if false;
    }
  }
}
```

### Metadata Management

```python
# Custom metadata stored with each image
custom_metadata = {
    "uploader": user_id,
    "upload_source": "html_editor",
    "newsletter_id": newsletter_id,
    "event_date": "2024-04-15",
    "tags": "spring,festival,students",
    "alt_text": "Students performing traditional dance",
    "approval_status": "pending",
    "usage_rights": "school_internal"
}

result = await image_upload_tool(
    file=image_file,
    metadata=custom_metadata
)
```

## Image Processing

### Automatic Optimization

```python
# Default optimization pipeline
OPTIMIZATION_PIPELINE = [
    "strip_exif",           # Remove metadata for privacy
    "auto_orient",          # Fix rotation based on EXIF
    "compress_jpeg",        # Optimize JPEG compression
    "convert_to_webp",      # Convert to WebP when supported
    "generate_thumbnail",   # Create thumbnail version
    "validate_content"      # Check for inappropriate content
]

# Custom processing
processing_options = {
    "sharpen": True,
    "noise_reduction": True,
    "color_enhancement": False,
    "watermark": {
        "enabled": True,
        "text": "© School Newsletter 2024",
        "position": "bottom_right",
        "opacity": 0.3
    }
}
```

### Format Conversion

```python
# Automatic format selection based on content
def select_optimal_format(image_data: bytes) -> str:
    """Choose best format for image"""
    
    # Analyze image properties
    has_transparency = has_alpha_channel(image_data)
    color_count = count_colors(image_data)
    
    if has_transparency:
        return "png" if color_count < 256 else "webp"
    elif color_count < 256:
        return "png"  # Good for simple graphics
    else:
        return "webp"  # Best compression for photos
```

## Performance Optimization

### Caching Strategy

```python
# CDN and caching configuration
CACHE_CONFIG = {
    "cdn_enabled": True,
    "edge_locations": ["asia-northeast1", "us-central1"],
    "cache_duration_seconds": 86400 * 7,  # 1 week
    "enable_compression": True,
    "enable_brotli": True
}

# Generate URLs with cache optimization
def generate_optimized_url(storage_path: str, options: dict = None) -> str:
    """Generate CDN-optimized image URL"""
    base_url = f"https://cdn.example.com/{storage_path}"
    
    if options:
        params = []
        if options.get("width"):
            params.append(f"w={options['width']}")
        if options.get("quality"):
            params.append(f"q={options['quality']}")
        if options.get("format"):
            params.append(f"f={options['format']}")
        
        if params:
            base_url += "?" + "&".join(params)
    
    return base_url
```

### Lazy Loading Support

```python
# Generate responsive image HTML
def generate_responsive_image_html(upload_result: ImageUploadResult) -> str:
    """Create responsive image with lazy loading"""
    
    return f'''
    <picture>
        <source srcset="{upload_result.url}?f=webp" type="image/webp">
        <source srcset="{upload_result.url}?f=jpeg" type="image/jpeg">
        <img 
            src="{upload_result.url}" 
            alt="{upload_result.alt_text}"
            width="{upload_result.width}"
            height="{upload_result.height}"
            loading="lazy"
            decoding="async"
            style="max-width: 100%; height: auto;"
        >
    </picture>
    '''
```

## Content Moderation

### Automated Checks

```python
# Content safety validation
MODERATION_CHECKS = [
    "explicit_content",     # Adult content detection
    "violence",            # Violence detection
    "inappropriate_text",  # Text in images
    "privacy_violation",   # Personal information
    "copyright_check"      # Reverse image search
]

async def moderate_image(image_data: bytes) -> ModerationResult:
    """Check image content for policy violations"""
    
    # Use Google Cloud Vision API for content detection
    vision_client = vision.ImageAnnotatorClient()
    image = vision.Image(content=image_data)
    
    # Safe search detection
    safe_search = vision_client.safe_search_detection(image=image)
    annotations = safe_search.safe_search_annotation
    
    return ModerationResult(
        is_safe=all([
            annotations.adult < vision.Likelihood.LIKELY,
            annotations.violence < vision.Likelihood.LIKELY,
            annotations.racy < vision.Likelihood.LIKELY
        ]),
        confidence=0.95,
        reasons=[]
    )
```

## Testing

### Unit Tests

```python
import pytest
from unittest.mock import Mock, patch
from adk_tools import image_upload_tool

@pytest.mark.asyncio
async def test_basic_upload():
    """Test basic image upload functionality"""
    mock_file = Mock()
    mock_file.read.return_value = b"fake_image_data"
    mock_file.content_type = "image/jpeg"
    mock_file.filename = "test.jpg"
    
    with patch('adk_tools.firebase_storage.upload') as mock_upload:
        mock_upload.return_value = "https://storage.googleapis.com/test.jpg"
        
        result = await image_upload_tool(file=mock_file)
        
        assert result.url.startswith("https://")
        assert result.content_type == "image/jpeg"
        assert result.file_name == "test.jpg"

@pytest.mark.asyncio
async def test_file_size_validation():
    """Test file size limit enforcement"""
    large_file = Mock()
    large_file.size = 20 * 1024 * 1024  # 20MB
    
    with pytest.raises(FileSizeError):
        await image_upload_tool(file=large_file)

@pytest.mark.asyncio
async def test_unsupported_format():
    """Test unsupported file format rejection"""
    exe_file = Mock()
    exe_file.content_type = "application/octet-stream"
    exe_file.filename = "virus.exe"
    
    with pytest.raises(FileTypeError):
        await image_upload_tool(file=exe_file)
```

### Integration Tests

```python
@pytest.mark.integration
@pytest.mark.asyncio
async def test_firebase_storage_integration():
    """Test actual Firebase Storage upload"""
    
    # Create test image
    test_image = create_test_image(width=100, height=100, format="PNG")
    
    # Upload to staging bucket
    result = await image_upload_tool(
        file=test_image,
        folder="test_uploads",
        resize_options=ImageResizeOptions(max_width=50, quality=90)
    )
    
    # Verify upload
    assert result.url is not None
    assert result.was_resized
    assert result.width == 50
    assert result.height == 50
    
    # Verify image is accessible
    response = requests.get(result.url)
    assert response.status_code == 200
    assert response.headers['content-type'].startswith('image/')
    
    # Cleanup
    await delete_test_image(result.storage_path)
```

## Monitoring and Analytics

### Upload Metrics

```python
# Track upload performance and usage
METRICS = {
    "uploads_per_minute": 0,
    "total_storage_used_mb": 0,
    "average_file_size_kb": 0,
    "popular_formats": {},
    "upload_success_rate": 0.0,
    "average_processing_time_ms": 0
}

async def track_upload_metrics(result: ImageUploadResult):
    """Record metrics for monitoring"""
    
    metrics_data = {
        "timestamp": datetime.utcnow(),
        "file_size_bytes": result.file_size_bytes,
        "format": result.format,
        "was_resized": result.was_resized,
        "compression_ratio": result.compression_ratio,
        "upload_duration_ms": result.processing_time_ms
    }
    
    # Send to monitoring service
    await metrics_collector.record(metrics_data)
```

## Related Documentation

- [ADK Workflow Guide](../../guides/adk-workflow.md)
- [HTML Editor Tool API Reference](html_editor_tool.md)
- [Firebase Storage Configuration](../../guides/firebase-setup.md)
- [Image Processing Pipeline](../../guides/image-optimization.md)