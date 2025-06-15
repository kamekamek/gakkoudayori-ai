class SceneManager {
    constructor() {
        this.scene = null;
        this.camera = null;
        this.renderer = null;
        this.controls = null;
        this.particles = [];
        this.buildings = [];
        this.animationId = null;
        this.isXRSupported = false;
        
        this.init();
    }

    init() {
        this.setupScene();
        this.createBuildings();
        this.createParticles();
        this.createLighting();
        this.setupControls();
        this.checkXRSupport();
        this.animate();
        
        // Window resize handler
        window.addEventListener('resize', () => this.onWindowResize());
    }

    setupScene() {
        // Scene
        this.scene = new THREE.Scene();
        this.scene.fog = new THREE.Fog(0x0f0f23, 50, 200);

        // Camera
        this.camera = new THREE.PerspectiveCamera(
            75,
            window.innerWidth / window.innerHeight,
            0.1,
            1000
        );
        this.camera.position.set(0, 20, 50);

        // Renderer
        const canvas = document.getElementById('webgl-canvas');
        this.renderer = new THREE.WebGLRenderer({ 
            canvas: canvas,
            antialias: true,
            alpha: true 
        });
        this.renderer.setSize(window.innerWidth, window.innerHeight);
        this.renderer.setPixelRatio(window.devicePixelRatio);
        this.renderer.shadowMap.enabled = true;
        this.renderer.shadowMap.type = THREE.PCFSoftShadowMap;
        this.renderer.outputEncoding = THREE.sRGBEncoding;
        this.renderer.toneMapping = THREE.ACESFilmicToneMapping;
        this.renderer.toneMappingExposure = 1.2;
    }

    createBuildings() {
        const buildingGeometry = new THREE.BoxGeometry(8, 30, 8);
        const buildingMaterials = [
            new THREE.MeshPhongMaterial({ 
                color: 0x00ffff, 
                transparent: true, 
                opacity: 0.7,
                emissive: 0x004444
            }),
            new THREE.MeshPhongMaterial({ 
                color: 0x0080ff, 
                transparent: true, 
                opacity: 0.7,
                emissive: 0x002244
            }),
            new THREE.MeshPhongMaterial({ 
                color: 0xff6b6b, 
                transparent: true, 
                opacity: 0.7,
                emissive: 0x442222
            })
        ];

        // Create building arrangement
        const positions = [
            [-30, 15, -20], [30, 15, -20], [0, 15, -40],
            [-20, 15, 20], [20, 15, 20], [-40, 15, 0], [40, 15, 0]
        ];

        positions.forEach((pos, index) => {
            const building = new THREE.Mesh(
                buildingGeometry,
                buildingMaterials[index % buildingMaterials.length]
            );
            building.position.set(pos[0], pos[1], pos[2]);
            building.castShadow = true;
            building.receiveShadow = true;
            
            // Add pulsing animation data
            building.userData = { 
                originalY: pos[1],
                phase: index * 0.5,
                speed: 0.01 + Math.random() * 0.02
            };
            
            this.buildings.push(building);
            this.scene.add(building);
        });
    }

    createParticles() {
        const particleGeometry = new THREE.BufferGeometry();
        const particleCount = 1000;
        const positions = new Float32Array(particleCount * 3);
        const colors = new Float32Array(particleCount * 3);

        for (let i = 0; i < particleCount; i++) {
            positions[i * 3] = (Math.random() - 0.5) * 200;
            positions[i * 3 + 1] = (Math.random() - 0.5) * 200;
            positions[i * 3 + 2] = (Math.random() - 0.5) * 200;

            // Color variation (cyan to blue)
            const color = new THREE.Color();
            color.setHSL(0.5 + Math.random() * 0.2, 1, 0.5 + Math.random() * 0.5);
            colors[i * 3] = color.r;
            colors[i * 3 + 1] = color.g;
            colors[i * 3 + 2] = color.b;
        }

        particleGeometry.setAttribute('position', new THREE.BufferAttribute(positions, 3));
        particleGeometry.setAttribute('color', new THREE.BufferAttribute(colors, 3));

        const particleMaterial = new THREE.PointsMaterial({
            size: 2,
            vertexColors: true,
            transparent: true,
            opacity: 0.8,
            blending: THREE.AdditiveBlending
        });

        const particles = new THREE.Points(particleGeometry, particleMaterial);
        this.particles.push(particles);
        this.scene.add(particles);
    }

    createLighting() {
        // Ambient light
        const ambientLight = new THREE.AmbientLight(0x404040, 0.3);
        this.scene.add(ambientLight);

        // Directional light (main)
        const directionalLight = new THREE.DirectionalLight(0x00ffff, 1);
        directionalLight.position.set(50, 50, 50);
        directionalLight.castShadow = true;
        directionalLight.shadow.mapSize.width = 2048;
        directionalLight.shadow.mapSize.height = 2048;
        this.scene.add(directionalLight);

        // Point lights for ambiance
        const pointLight1 = new THREE.PointLight(0x0080ff, 1, 100);
        pointLight1.position.set(-50, 30, 0);
        this.scene.add(pointLight1);

        const pointLight2 = new THREE.PointLight(0xff6b6b, 1, 100);
        pointLight2.position.set(50, 30, 0);
        this.scene.add(pointLight2);

        // Hemisphere light for natural feel
        const hemisphereLight = new THREE.HemisphereLight(0x87CEEB, 0x0f0f23, 0.6);
        this.scene.add(hemisphereLight);
    }

    setupControls() {
        if (typeof THREE.OrbitControls !== 'undefined') {
            this.controls = new THREE.OrbitControls(this.camera, this.renderer.domElement);
            this.controls.enableDamping = true;
            this.controls.dampingFactor = 0.05;
            this.controls.enableZoom = true;
            this.controls.enablePan = true;
            this.controls.maxPolarAngle = Math.PI / 2;
            this.controls.minDistance = 20;
            this.controls.maxDistance = 200;
        }
    }

    async checkXRSupport() {
        if ('xr' in navigator) {
            try {
                const isSupported = await navigator.xr.isSessionSupported('immersive-vr');
                if (isSupported) {
                    this.isXRSupported = true;
                    document.getElementById('xr-btn').style.display = 'block';
                }
            } catch (error) {
                console.log('XR not supported:', error);
            }
        }
    }

    animate() {
        this.animationId = requestAnimationFrame(() => this.animate());

        const time = Date.now() * 0.001;

        // Animate buildings
        this.buildings.forEach(building => {
            const userData = building.userData;
            building.position.y = userData.originalY + Math.sin(time * userData.speed + userData.phase) * 2;
            building.rotation.y += userData.speed * 0.5;
        });

        // Animate particles
        this.particles.forEach(particle => {
            particle.rotation.y += 0.002;
            particle.rotation.x += 0.001;
        });

        // Update controls
        if (this.controls) {
            this.controls.update();
        }

        this.renderer.render(this.scene, this.camera);
    }

    onWindowResize() {
        this.camera.aspect = window.innerWidth / window.innerHeight;
        this.camera.updateProjectionMatrix();
        this.renderer.setSize(window.innerWidth, window.innerHeight);
    }

    // Tour experience methods
    startVirtualTour() {
        // Animate camera to tour positions
        const tourPositions = [
            { x: -30, y: 25, z: 30 },
            { x: 0, y: 40, z: 60 },
            { x: 30, y: 25, z: -30 },
            { x: 0, y: 20, z: 50 }
        ];

        let currentIndex = 0;
        const animateTour = () => {
            if (currentIndex < tourPositions.length) {
                const targetPos = tourPositions[currentIndex];
                this.animateCameraTo(targetPos, 2000, () => {
                    currentIndex++;
                    setTimeout(animateTour, 3000);
                });
            }
        };
        animateTour();
    }

    animateCameraTo(targetPosition, duration, onComplete) {
        const startPos = this.camera.position.clone();
        const startTime = Date.now();

        const animate = () => {
            const elapsed = Date.now() - startTime;
            const progress = Math.min(elapsed / duration, 1);
            
            // Smooth easing
            const easeProgress = 1 - Math.cos(progress * Math.PI / 2);
            
            this.camera.position.lerpVectors(startPos, new THREE.Vector3(
                targetPosition.x, targetPosition.y, targetPosition.z
            ), easeProgress);

            if (progress < 1) {
                requestAnimationFrame(animate);
            } else if (onComplete) {
                onComplete();
            }
        };
        animate();
    }

    showTechDemo() {
        // Create tech demo elements
        const demoGeometry = new THREE.SphereGeometry(5, 32, 32);
        const demoMaterial = new THREE.MeshPhongMaterial({
            color: 0x00ff00,
            transparent: true,
            opacity: 0.7,
            emissive: 0x002200
        });

        const demoSphere = new THREE.Mesh(demoGeometry, demoMaterial);
        demoSphere.position.set(0, 30, 0);
        this.scene.add(demoSphere);

        // Animate demo sphere
        const animateDemo = () => {
            demoSphere.rotation.x += 0.02;
            demoSphere.rotation.y += 0.03;
            demoSphere.position.y = 30 + Math.sin(Date.now() * 0.005) * 5;
        };

        const demoInterval = setInterval(animateDemo, 16);
        
        // Remove after 10 seconds
        setTimeout(() => {
            clearInterval(demoInterval);
            this.scene.remove(demoSphere);
        }, 10000);
    }

    dispose() {
        if (this.animationId) {
            cancelAnimationFrame(this.animationId);
        }
        
        // Clean up Three.js resources
        this.scene.traverse(object => {
            if (object.geometry) object.geometry.dispose();
            if (object.material) {
                if (Array.isArray(object.material)) {
                    object.material.forEach(material => material.dispose());
                } else {
                    object.material.dispose();
                }
            }
        });
        
        this.renderer.dispose();
    }
}

// Scene Manager instance will be created in app.js