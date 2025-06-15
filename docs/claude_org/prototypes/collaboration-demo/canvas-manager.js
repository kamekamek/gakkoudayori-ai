class CanvasManager {
    constructor(canvasId) {
        this.canvas = new fabric.Canvas(canvasId);
        this.currentTool = 'pen';
        this.currentColor = '#000000';
        this.isDrawing = false;
        this.brushSize = 5;
        this.remoteCursors = new Map();
        
        this.setupCanvas();
        this.setupTools();
        this.setupEventListeners();
    }

    setupCanvas() {
        // Canvas basic settings
        this.canvas.isDrawingMode = true;
        this.canvas.freeDrawingBrush.width = this.brushSize;
        this.canvas.freeDrawingBrush.color = this.currentColor;
        
        // Performance optimizations
        this.canvas.renderOnAddRemove = true;
        this.canvas.skipTargetFind = false;
        
        // Grid background
        this.addGrid();
        
        // Setup canvas dimensions
        this.resizeCanvas();
        window.addEventListener('resize', () => this.resizeCanvas());
    }

    addGrid() {
        const gridSize = 20;
        const canvasWidth = this.canvas.width;
        const canvasHeight = this.canvas.height;
        
        const grid = new fabric.Group([], {
            selectable: false,
            evented: false,
            excludeFromExport: true
        });
        
        // Vertical lines
        for (let i = 0; i <= canvasWidth; i += gridSize) {
            const line = new fabric.Line([i, 0, i, canvasHeight], {
                stroke: '#f0f0f0',
                strokeWidth: 1,
                selectable: false,
                evented: false
            });
            grid.addWithUpdate(line);
        }
        
        // Horizontal lines
        for (let i = 0; i <= canvasHeight; i += gridSize) {
            const line = new fabric.Line([0, i, canvasWidth, i], {
                stroke: '#f0f0f0',
                strokeWidth: 1,
                selectable: false,
                evented: false
            });
            grid.addWithUpdate(line);
        }
        
        this.canvas.add(grid);
        this.canvas.sendToBack(grid);
    }

    setupTools() {
        // Tool buttons
        document.getElementById('pen-tool').addEventListener('click', () => {
            this.setTool('pen');
        });
        
        document.getElementById('eraser-tool').addEventListener('click', () => {
            this.setTool('eraser');
        });
        
        document.getElementById('text-tool').addEventListener('click', () => {
            this.setTool('text');
        });
        
        document.getElementById('shape-tool').addEventListener('click', () => {
            this.setTool('shape');
        });
        
        // Color palette
        document.querySelectorAll('.color-option').forEach(option => {
            option.addEventListener('click', (e) => {
                this.setColor(e.target.dataset.color);
                
                // Update active color
                document.querySelectorAll('.color-option').forEach(opt => 
                    opt.classList.remove('active')
                );
                e.target.classList.add('active');
            });
        });
        
        // Zoom controls
        document.getElementById('zoom-in').addEventListener('click', () => {
            this.zoom(1.2);
        });
        
        document.getElementById('zoom-out').addEventListener('click', () => {
            this.zoom(0.8);
        });
        
        document.getElementById('zoom-reset').addEventListener('click', () => {
            this.canvas.setZoom(1);
            this.canvas.absolutePan({ x: 0, y: 0 });
        });
        
        // Action buttons
        document.getElementById('clear-canvas').addEventListener('click', () => {
            this.clearCanvas();
        });
        
        document.getElementById('save-project').addEventListener('click', () => {
            this.saveProject();
        });
        
        document.getElementById('export-project').addEventListener('click', () => {
            this.exportProject();
        });
    }

    setupEventListeners() {
        // Canvas events
        this.canvas.on('path:created', (e) => {
            this.onCanvasEvent('path:created', {
                path: e.path,
                color: this.currentColor,
                brushSize: this.brushSize
            });
        });
        
        this.canvas.on('text:added', (e) => {
            this.onCanvasEvent('text:added', {
                text: e.target.text,
                x: e.target.left,
                y: e.target.top,
                color: this.currentColor
            });
        });
        
        this.canvas.on('object:added', (e) => {
            if (e.target.type !== 'path' && e.target.type !== 'textbox') {
                this.onCanvasEvent('object:added', {
                    object: e.target,
                    x: e.target.left,
                    y: e.target.top
                });
            }
        });
        
        this.canvas.on('object:modified', (e) => {
            this.onCanvasEvent('object:modified', {
                object: e.target,
                x: e.target.left,
                y: e.target.top
            });
        });
        
        this.canvas.on('mouse:move', (e) => {
            if (e.e) {
                const pointer = this.canvas.getPointer(e.e);
                this.updateCoordinates(pointer.x, pointer.y);
                this.onCursorMove(pointer.x, pointer.y);
            }
        });
    }

    setTool(tool) {
        this.currentTool = tool;
        
        // Update tool buttons
        document.querySelectorAll('.tool-btn').forEach(btn => 
            btn.classList.remove('active')
        );
        document.getElementById(tool + '-tool').classList.add('active');
        
        // Configure canvas based on tool
        switch (tool) {
            case 'pen':
                this.canvas.isDrawingMode = true;
                this.canvas.selection = false;
                this.canvas.freeDrawingBrush = new fabric.PencilBrush(this.canvas);
                this.canvas.freeDrawingBrush.width = this.brushSize;
                this.canvas.freeDrawingBrush.color = this.currentColor;
                break;
                
            case 'eraser':
                this.canvas.isDrawingMode = true;
                this.canvas.selection = false;
                this.canvas.freeDrawingBrush = new fabric.EraserBrush(this.canvas);
                this.canvas.freeDrawingBrush.width = this.brushSize * 2;
                break;
                
            case 'text':
                this.canvas.isDrawingMode = false;
                this.canvas.selection = true;
                break;
                
            case 'shape':
                this.canvas.isDrawingMode = false;
                this.canvas.selection = true;
                break;
        }
    }

    setColor(color) {
        this.currentColor = color;
        if (this.canvas.freeDrawingBrush) {
            this.canvas.freeDrawingBrush.color = color;
        }
    }

    zoom(factor) {
        const zoom = this.canvas.getZoom() * factor;
        if (zoom > 5) return;
        if (zoom < 0.2) return;
        
        this.canvas.setZoom(zoom);
    }

    updateCoordinates(x, y) {
        document.getElementById('coordinates').textContent = 
            `X: ${Math.round(x)}, Y: ${Math.round(y)}`;
    }

    // Text tool functionality
    addText(x, y, text = 'テキストを入力') {
        if (this.currentTool !== 'text') return;
        
        const textbox = new fabric.IText(text, {
            left: x,
            top: y,
            width: 200,
            fontSize: 16,
            fill: this.currentColor,
            fontFamily: 'Arial',
            cornerColor: '#3498db',
            cornerSize: 6
        });
        
        this.canvas.add(textbox);
        this.canvas.setActiveObject(textbox);
        textbox.enterEditing();
    }

    // Shape tool functionality
    addShape(type, x, y) {
        if (this.currentTool !== 'shape') return;
        
        let shape;
        const options = {
            left: x,
            top: y,
            fill: this.currentColor,
            stroke: this.currentColor,
            strokeWidth: 2,
            cornerColor: '#3498db',
            cornerSize: 6
        };
        
        switch (type) {
            case 'rectangle':
                shape = new fabric.Rect({
                    ...options,
                    width: 100,
                    height: 60
                });
                break;
                
            case 'circle':
                shape = new fabric.Circle({
                    ...options,
                    radius: 40
                });
                break;
                
            case 'triangle':
                shape = new fabric.Triangle({
                    ...options,
                    width: 80,
                    height: 80
                });
                break;
                
            default:
                return;
        }
        
        this.canvas.add(shape);
        this.canvas.setActiveObject(shape);
    }

    // Remote collaboration
    handleRemoteEvent(eventData) {
        const { userId, userName, eventType, data } = eventData;
        
        switch (eventType) {
            case 'path:created':
                this.addRemotePath(data, userId);
                break;
                
            case 'text:added':
                this.addRemoteText(data, userId);
                break;
                
            case 'object:added':
                this.addRemoteObject(data, userId);
                break;
                
            case 'demo:shape':
                this.addDemoShape(data);
                break;
                
            case 'collaboration:action':
                this.handleCollaborationAction(data);
                break;
        }
    }

    addRemotePath(data, userId) {
        // Create remote path with different styling
        const path = new fabric.Path(data.path);
        path.set({
            stroke: data.color || '#e74c3c',
            strokeWidth: data.brushSize || 3,
            fill: '',
            selectable: false,
            evented: false,
            opacity: 0.8
        });
        
        this.canvas.add(path);
        
        // Animate path appearance
        path.animate('opacity', 1, {
            duration: 300,
            easing: fabric.util.ease.easeOutCubic
        });
    }

    addRemoteText(data, userId) {
        const text = new fabric.IText(data.text, {
            left: data.x,
            top: data.y,
            fill: data.color || '#e74c3c',
            fontSize: 16,
            fontFamily: 'Arial',
            selectable: false,
            evented: false,
            opacity: 0
        });
        
        this.canvas.add(text);
        
        // Animate text appearance
        text.animate('opacity', 0.9, {
            duration: 500,
            easing: fabric.util.ease.easeOutBounce
        });
    }

    addRemoteObject(data, userId) {
        // Create remote objects based on type
        let object;
        const objectData = data.object;
        
        switch (objectData.type) {
            case 'circle':
                object = new fabric.Circle({
                    left: data.x,
                    top: data.y,
                    radius: objectData.radius || 30,
                    fill: objectData.color || '#e74c3c',
                    opacity: 0,
                    selectable: false,
                    evented: false
                });
                break;
                
            case 'rectangle':
                object = new fabric.Rect({
                    left: data.x,
                    top: data.y,
                    width: objectData.width || 60,
                    height: objectData.height || 40,
                    fill: objectData.color || '#e74c3c',
                    opacity: 0,
                    selectable: false,
                    evented: false
                });
                break;
        }
        
        if (object) {
            this.canvas.add(object);
            object.animate('opacity', 0.8, {
                duration: 400,
                easing: fabric.util.ease.easeOutCubic
            });
        }
    }

    addDemoShape(data) {
        let shape;
        const { type, x, y } = data;
        
        switch (type) {
            case 'circle':
                shape = new fabric.Circle({
                    left: x,
                    top: y,
                    radius: data.radius,
                    fill: 'transparent',
                    stroke: '#3498db',
                    strokeWidth: 3,
                    opacity: 0
                });
                break;
                
            case 'rectangle':
                shape = new fabric.Rect({
                    left: x,
                    top: y,
                    width: data.width,
                    height: data.height,
                    fill: 'transparent',
                    stroke: '#3498db',
                    strokeWidth: 3,
                    opacity: 0
                });
                break;
                
            case 'line':
                shape = new fabric.Line([data.x1, data.y1, data.x2, data.y2], {
                    stroke: '#3498db',
                    strokeWidth: 3,
                    opacity: 0
                });
                break;
        }
        
        if (shape) {
            this.canvas.add(shape);
            shape.animate('opacity', 1, {
                duration: 1000,
                easing: fabric.util.ease.easeOutCubic
            });
        }
    }

    handleCollaborationAction(data) {
        const { action, data: actionData } = data;
        
        switch (action) {
            case 'addText':
                this.addRemoteText(actionData, 'demo');
                break;
                
            case 'addArrow':
                this.addArrow(actionData);
                break;
                
            case 'addNote':
                this.addStickyNote(actionData);
                break;
        }
    }

    addArrow(data) {
        const { x1, y1, x2, y2 } = data;
        
        // Arrow line
        const line = new fabric.Line([x1, y1, x2, y2], {
            stroke: '#f39c12',
            strokeWidth: 3,
            opacity: 0
        });
        
        // Arrow head
        const angle = Math.atan2(y2 - y1, x2 - x1);
        const headLength = 15;
        
        const arrowHead = new fabric.Polygon([
            { x: x2, y: y2 },
            { 
                x: x2 - headLength * Math.cos(angle - Math.PI / 6), 
                y: y2 - headLength * Math.sin(angle - Math.PI / 6) 
            },
            { 
                x: x2 - headLength * Math.cos(angle + Math.PI / 6), 
                y: y2 - headLength * Math.sin(angle + Math.PI / 6) 
            }
        ], {
            fill: '#f39c12',
            opacity: 0,
            selectable: false,
            evented: false
        });
        
        this.canvas.add(line);
        this.canvas.add(arrowHead);
        
        line.animate('opacity', 1, { duration: 500 });
        arrowHead.animate('opacity', 1, { duration: 500 });
    }

    addStickyNote(data) {
        const note = new fabric.Group([
            new fabric.Rect({
                width: 120,
                height: 80,
                fill: '#f1c40f',
                stroke: '#f39c12',
                strokeWidth: 1
            }),
            new fabric.IText(data.text, {
                fontSize: 12,
                fill: '#2c3e50',
                textAlign: 'center',
                originX: 'center',
                originY: 'center'
            })
        ], {
            left: data.x,
            top: data.y,
            opacity: 0,
            selectable: false,
            evented: false
        });
        
        this.canvas.add(note);
        note.animate('opacity', 0.9, {
            duration: 600,
            easing: fabric.util.ease.easeOutBounce
        });
    }

    // Remote cursor management
    updateRemoteCursor(userId, x, y, userName) {
        let cursor = this.remoteCursors.get(userId);
        
        if (!cursor) {
            cursor = this.createRemoteCursor(userId, userName);
            this.remoteCursors.set(userId, cursor);
        }
        
        cursor.style.left = x + 'px';
        cursor.style.top = y + 'px';
        cursor.style.display = 'block';
        
        // Hide cursor after inactivity
        clearTimeout(cursor.hideTimeout);
        cursor.hideTimeout = setTimeout(() => {
            cursor.style.display = 'none';
        }, 3000);
    }

    createRemoteCursor(userId, userName) {
        const cursor = document.createElement('div');
        cursor.className = 'remote-cursor';
        cursor.setAttribute('data-user', userName);
        cursor.style.display = 'none';
        
        document.getElementById('cursors-container').appendChild(cursor);
        return cursor;
    }

    removeRemoteCursor(userId) {
        const cursor = this.remoteCursors.get(userId);
        if (cursor) {
            cursor.remove();
            this.remoteCursors.delete(userId);
        }
    }

    // Canvas management
    clearCanvas() {
        if (confirm('キャンバスをクリアしますか？この操作は元に戻せません。')) {
            this.canvas.clear();
            this.addGrid();
            this.onCanvasEvent('canvas:cleared', {});
        }
    }

    saveProject() {
        const projectData = {
            version: '1.0',
            timestamp: new Date().toISOString(),
            canvas: this.canvas.toJSON(),
            settings: {
                tool: this.currentTool,
                color: this.currentColor,
                brushSize: this.brushSize
            }
        };
        
        const dataStr = JSON.stringify(projectData, null, 2);
        const blob = new Blob([dataStr], { type: 'application/json' });
        const url = URL.createObjectURL(blob);
        
        const link = document.createElement('a');
        link.href = url;
        link.download = `collaboration_project_${Date.now()}.json`;
        link.click();
        
        URL.revokeObjectURL(url);
    }

    exportProject() {
        const dataURL = this.canvas.toDataURL({
            format: 'png',
            quality: 1,
            multiplier: 2
        });
        
        const link = document.createElement('a');
        link.href = dataURL;
        link.download = `collaboration_export_${Date.now()}.png`;
        link.click();
    }

    resizeCanvas() {
        const container = document.getElementById('canvas-container');
        const toolbar = document.getElementById('canvas-toolbar');
        
        const availableWidth = container.clientWidth - 40; // margin
        const availableHeight = container.clientHeight - toolbar.clientHeight - 40;
        
        this.canvas.setDimensions({
            width: Math.min(availableWidth, 800),
            height: Math.min(availableHeight, 600)
        });
    }

    // Event handlers (to be set by the main app)
    onCanvasEvent(eventType, data) {
        // Will be overridden by main app
    }

    onCursorMove(x, y) {
        // Will be overridden by main app
    }
}

// Export for use in other modules
window.CanvasManager = CanvasManager;