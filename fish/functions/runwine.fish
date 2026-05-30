function runwine
    env \
        __EGL_VENDOR_LIBRARY_FILENAMES="/usr/share/glvnd/egl_vendor.d/10_nvidia.json" \
        __GLX_VENDOR_LIBRARY_NAME="nvidia" \
        __GL_GSYNC_ALLOWED=1 \
        __GL_SHADER_DISK_CACHE=1 \
        __GL_SHADER_DISK_CACHE_SIZE=2147483648 \
        __GL_SHADER_DISK_CACHE_PATH="$HOME/.cache/nv_shaders" \
        __GL_SYNC_TO_VBLANK=0 \
        __GL_THREADED_OPTIMIZATIONS=1 \
        __GL_VRR_ALLOWED=1 \
        wine $argv
end
