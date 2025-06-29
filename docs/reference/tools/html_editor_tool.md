# HTML Editor Tool API Reference

## Overview

The HTML Editor Tool provides a WYSIWYG (What You See Is What You Get) interface for editing HTML content within the ADK workflow. It allows users to modify specific regions of generated HTML while maintaining the overall layout structure.

## Tool Definition

```python
@tool
async def html_editor_tool(
    html: str,
    editable_regions: List[str] = None,
    allowed_tags: List[str] = None,
    max_content_length: int = 50000,
    theme: str = "default"
) -> HtmlEditorResult:
    """
    Launch HTML editor interface for content editing.
    
    Args:
        html: Initial HTML content to edit
        editable_regions: List of CSS selectors or element IDs that can be edited
        allowed_tags: HTML tags permitted in edited content
        max_content_length: Maximum character limit for content
        theme: Editor theme (default, dark, school)
    
    Returns:
        HtmlEditorResult: Contains edited HTML and metadata
    
    Raises:
        ValidationError: Invalid HTML or parameters
        ContentTooLargeError: Content exceeds size limits
        PermissionError: Attempting to edit restricted regions
    """
```

## Data Models

### HtmlEditorResult

```python
@dataclass
class HtmlEditorResult:
    """Result returned from HTML Editor Tool"""
    
    # Core data
    html: str                    # Edited HTML content
    original_html: str           # Original HTML for comparison
    
    # Editing metadata
    edit_regions: List[str]      # Regions that were modified
    edit_count: int              # Number of edits made
    editing_time_seconds: int    # Time spent editing
    
    # Content analysis
    word_count: int              # Total word count
    image_count: int             # Number of images
    has_unsaved_changes: bool    # Whether there are pending changes
    
    # Validation results
    is_valid_html: bool          # HTML validation status
    validation_errors: List[str] # Any validation issues
    accessibility_score: float  # A11y compliance score (0-100)
    
    # Tool interaction
    tools_used: List[str]        # Other tools called during editing
    upload_urls: List[str]       # URLs of uploaded images
```

### EditorConfig

```python
@dataclass
class EditorConfig:
    """Configuration for HTML Editor Tool"""
    
    # Editing permissions
    editable_regions: List[str] = field(default_factory=list)
    allowed_tags: List[str] = field(default_factory=lambda: [
        'p', 'h1', 'h2', 'h3', 'h4', 'h5', 'h6',
        'ul', 'ol', 'li', 'br', 'strong', 'em',
        'img', 'a', 'table', 'tr', 'td', 'th'
    ])
    
    # Content limits
    max_content_length: int = 50000
    max_image_size_mb: int = 5
    max_images_per_document: int = 20
    
    # UI preferences
    theme: str = "default"
    toolbar_items: List[str] = field(default_factory=lambda: [
        'bold', 'italic', 'underline', 'heading',
        'bullet_list', 'number_list', 'image', 'link'
    ])
    
    # Integration settings
    auto_save_interval_seconds: int = 30
    enable_image_upload: bool = True
    enable_spell_check: bool = True
    enable_accessibility_hints: bool = True
```

## Usage Examples

### Basic Usage

```python
from adk_tools import html_editor_tool

# Simple content editing
result = await html_editor_tool(
    html='<div id="content"><p>Edit this text</p></div>',
    editable_regions=['#content']
)

print(f"Edited HTML: {result.html}")
print(f"Edit count: {result.edit_count}")
```

### Advanced Configuration

```python
# Restrict editing to specific regions with custom settings
result = await html_editor_tool(
    html=layout_html,
    editable_regions=['#main-content', '#sidebar', '.editable'],
    allowed_tags=['p', 'h2', 'h3', 'ul', 'li', 'strong', 'em', 'img'],
    max_content_length=25000,
    theme="school"
)

# Check for validation issues
if not result.is_valid_html:
    print("HTML validation errors:", result.validation_errors)

# Analyze content changes
if result.edit_count > 0:
    print(f"Modified regions: {result.edit_regions}")
    print(f"New word count: {result.word_count}")
    print(f"Images added: {len(result.upload_urls)}")
```

### Integration with Image Upload

```python
# Editor automatically integrates with Image Upload Tool
result = await html_editor_tool(
    html=base_html,
    editable_regions=['#photos-section'],
    theme="school"
)

# Check if images were uploaded during editing
if result.upload_urls:
    print("Images uploaded:", result.upload_urls)
    print("Total images in document:", result.image_count)
```

## Error Handling

### Common Exceptions

```python
from adk_tools.exceptions import (
    ValidationError,
    ContentTooLargeError,
    PermissionError,
    ImageUploadError
)

try:
    result = await html_editor_tool(html=content)
except ValidationError as e:
    print(f"Invalid HTML: {e.message}")
    print(f"Line: {e.line}, Column: {e.column}")
    
except ContentTooLargeError as e:
    print(f"Content too large: {e.size_bytes} bytes (max: {e.max_size_bytes})")
    
except PermissionError as e:
    print(f"Cannot edit region: {e.region}")
    print(f"Allowed regions: {e.allowed_regions}")
    
except ImageUploadError as e:
    print(f"Image upload failed: {e.filename}")
    print(f"Reason: {e.reason}")
```

### Validation and Recovery

```python
# Validate before editing
def validate_html_input(html: str) -> bool:
    """Pre-validate HTML content"""
    if len(html) > 100000:  # 100KB limit
        return False
    
    # Check for malicious content
    dangerous_tags = ['script', 'iframe', 'object', 'embed']
    for tag in dangerous_tags:
        if f'<{tag}' in html.lower():
            return False
    
    return True

# Handle editing errors gracefully
async def safe_html_edit(html: str, **kwargs) -> HtmlEditorResult:
    """Wrapper with error handling"""
    if not validate_html_input(html):
        raise ValidationError("HTML content failed pre-validation")
    
    try:
        return await html_editor_tool(html=html, **kwargs)
    except Exception as e:
        # Log error and return original content
        logger.error(f"HTML editing failed: {e}")
        return HtmlEditorResult(
            html=html,  # Return original
            original_html=html,
            edit_count=0,
            is_valid_html=True,
            validation_errors=[str(e)]
        )
```

## Integration Points

### With Layout Agent

```python
# Receive HTML from Layout Agent
layout_response = await layout_agent.generate_html(
    theme="spring_festival",
    sections=["header", "content", "footer"]
)

# Pass to HTML Editor Tool
editor_result = await html_editor_tool(
    html=layout_response.html,
    editable_regions=layout_response.editable_regions,
    theme=layout_response.theme
)
```

### With PDF Export Agent

```python
# Edit content first
editor_result = await html_editor_tool(html=content)

# Validate before PDF generation
if editor_result.is_valid_html and editor_result.accessibility_score > 80:
    pdf_result = await pdf_export_agent.generate_pdf(
        html=editor_result.html,
        options={"format": "A4", "margin": "normal"}
    )
```

### With Image Upload Tool

The HTML Editor Tool automatically integrates with the Image Upload Tool when users insert images:

```python
# Image upload is triggered internally when user clicks "Insert Image"
# The editor will:
# 1. Open image selection dialog
# 2. Call image_upload_tool() for selected files
# 3. Insert returned URLs into HTML
# 4. Update result.upload_urls list
```

## Configuration Options

### Editor Themes

```python
# Available themes
THEMES = {
    "default": {
        "primary_color": "#1976d2",
        "toolbar_style": "modern",
        "font_family": "Roboto, sans-serif"
    },
    "school": {
        "primary_color": "#4caf50",
        "toolbar_style": "friendly",
        "font_family": "Comic Sans MS, cursive"
    },
    "dark": {
        "primary_color": "#bb86fc",
        "toolbar_style": "minimal",
        "font_family": "Source Code Pro, monospace"
    }
}
```

### Accessibility Features

```python
# Built-in accessibility checks
ACCESSIBILITY_CHECKS = [
    "alt_text_missing",      # Images without alt text
    "heading_structure",     # Proper heading hierarchy
    "color_contrast",        # Sufficient color contrast
    "keyboard_navigation",   # Tab order and focus
    "semantic_markup",       # Proper HTML semantics
]

# Configure accessibility scoring
accessibility_config = {
    "min_score": 80,         # Minimum score for validation
    "require_alt_text": True,
    "require_headings": True,
    "check_color_contrast": True
}
```

## Performance Considerations

### Optimization Tips

1. **Content Size**: Keep HTML under 50KB for optimal performance
2. **Image Optimization**: Compress images before upload
3. **Auto-save**: Use reasonable intervals (30-60 seconds)
4. **DOM Updates**: Batch DOM modifications for better performance

### Monitoring

```python
# Performance metrics included in result
performance_metrics = {
    "load_time_ms": result.editing_time_seconds * 1000,
    "dom_size": len(result.html),
    "image_count": result.image_count,
    "edit_operations": result.edit_count
}

# Log performance for optimization
logger.info(f"HTML Editor Performance: {performance_metrics}")
```

## Security Considerations

### Content Sanitization

- All HTML content is sanitized to prevent XSS attacks
- Only whitelisted HTML tags are allowed
- JavaScript and other executable content is stripped
- Image URLs are validated and scanned

### Access Control

- Only specified regions can be edited
- File upload permissions are enforced
- Content size limits prevent DoS attacks
- User session validation required

## Testing

### Unit Tests

```python
import pytest
from adk_tools import html_editor_tool

@pytest.mark.asyncio
async def test_basic_editing():
    """Test basic HTML editing functionality"""
    html = '<div id="test"><p>Original text</p></div>'
    
    result = await html_editor_tool(
        html=html,
        editable_regions=['#test']
    )
    
    assert result.original_html == html
    assert result.is_valid_html
    assert len(result.validation_errors) == 0

@pytest.mark.asyncio
async def test_invalid_region():
    """Test editing restricted regions"""
    html = '<div id="protected"><p>Protected content</p></div>'
    
    with pytest.raises(PermissionError):
        await html_editor_tool(
            html=html,
            editable_regions=['#allowed']  # Different from actual content
        )
```

### Integration Tests

```python
@pytest.mark.asyncio
async def test_full_workflow():
    """Test complete ADK workflow with HTML Editor"""
    # Generate initial layout
    layout = await layout_agent.generate_html(theme="test")
    
    # Edit content
    editor_result = await html_editor_tool(
        html=layout.html,
        editable_regions=['#content']
    )
    
    assert editor_result.is_valid_html
    
    # Generate PDF
    pdf_result = await pdf_export_agent.generate_pdf(
        html=editor_result.html
    )
    
    assert pdf_result.success
    assert len(pdf_result.pdf_bytes) > 0
```

## Related Documentation

- [ADK Workflow Guide](../../guides/adk-workflow.md)
- [Image Upload Tool API Reference](image_upload_tool.md)
- [Layout Agent Reference](../agents/layout_agent.md)
- [PDF Export Agent Reference](../agents/pdf_export_agent.md)