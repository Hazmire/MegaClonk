# Grimdark performance verification

Final isolated profile pending. No native Windows or gaming-GPU60FPS certification is claimed. The cloud renderer is Mesa llvmpipe software rendering.

Preserved: shared animated enemy MultiMeshes, distance-based animation detail, existing spatial/crowd simulation, pooled projectiles/FX/corpses, shared textured materials and instanced props. Ground cover is distance culled and boundary shadows are disabled. World renders once through the low-resolution viewport; HUD stays full resolution. Source precision values were changed from instance uniforms to shared material uniforms to avoid exhausting the4096-slot buffer during repeated stage rebuilds.
