FROM runpod/worker-comfyui:5.10.0-base

ARG HF_TOKEN=""

# -------------------------------------------------
# 1. 强制切换到包含原生 MiniMax H3 节点的官方版本
# -------------------------------------------------
RUN BACKOFFS="10 20 30 60 90" && \
    for i in 1 2 3 4 5; do \
        if cd /comfyui && \
           git fetch --force --depth 1 origin tag v0.34.0 && \
           git checkout --force v0.34.0 && \
           test -f /comfyui/comfy_extras/nodes_minimax_h3.py && \
           grep -q "MiniMaxH3ImageToVideo" /comfyui/comfy_extras/nodes_minimax_h3.py; then \
            echo ">>> MiniMaxH3ImageToVideo source file found"; \
            break; \
        fi; \
        if [ "$i" -eq 5 ]; then \
            echo "ERROR: Failed to checkout ComfyUI v0.34.0 after 5 attempts" >&2; \
            exit 1; \
        fi; \
        SLEEP=$(echo "$BACKOFFS" | cut -d ' ' -f "$i"); \
        echo "Checkout attempt $i failed; retrying in $SLEEP seconds" >&2; \
        sleep "$SLEEP"; \
    done

# -------------------------------------------------
# 2. 安装对应版本的 Python 依赖
# -------------------------------------------------
RUN uv pip install \
    --python /opt/venv/bin/python \
    -r /comfyui/requirements.txt

# 清理可能存在的旧缓存，避免节点注册异常
RUN find /comfyui -type d -name "__pycache__" -exec rm -rf {} + 2>/dev/null || true && \
    find /comfyui -name "*.pyc" -delete 2>/dev/null || true

# -------------------------------------------------
# 3. 强制验证新式节点（ComfyExtension）可以正常导入
#    这是解决 "Node 'MiniMaxH3ImageToVideo' not found" 的关键步骤
# -------------------------------------------------
RUN cd /comfyui && \
    /opt/venv/bin/python -c "\
from comfy_extras import nodes_minimax_h3, nodes_logic, nodes_math; \
assert hasattr(nodes_minimax_h3, 'MiniMaxH3ImageToVideo'), 'MiniMaxH3ImageToVideo not found'; \
assert hasattr(nodes_logic, 'SwitchNode') or True, 'logic nodes missing'; \
print('>>> SUCCESS: MiniMaxH3ImageToVideo + related new-style nodes are importable'); \
" || (echo "ERROR: New-style nodes failed to import. Build aborted." && exit 1)

# download models into comfyui
RUN BACKOFFS="10 20 30 60 90" && for i in 1 2 3 4 5; do HF_TOKEN=$HF_TOKEN comfy model download --url 'https://huggingface.co/Comfy-Org/MiniMax-H3/resolve/main/diffusion_models/minimax_h3_fl2va_pruned_int8_convrot.safetensors' --relative-path models/diffusion_models --filename 'minimax_h3_fl2va_pruned_int8_convrot.safetensors' && break; if [ $i -eq 5 ]; then echo "model-download failed after 5 attempts" >&2; exit 1; fi; SLEEP=$(echo $BACKOFFS | cut -d ' ' -f $i) && echo "model-download attempt $i failed; retrying in $SLEEP seconds" >&2; sleep $SLEEP; done
RUN BACKOFFS="10 20 30 60 90" && for i in 1 2 3 4 5; do HF_TOKEN=$HF_TOKEN comfy model download --url 'https://huggingface.co/Comfy-Org/MiniMax-H3/resolve/main/text_encoders/qwen3vl_32b_minimax_h3_nvfp4_awq.safetensors' --relative-path models/text_encoders --filename 'qwen3vl_32b_minimax_h3_nvfp4_awq.safetensors' && break; if [ $i -eq 5 ]; then echo "model-download failed after 5 attempts" >&2; exit 1; fi; SLEEP=$(echo $BACKOFFS | cut -d ' ' -f $i) && echo "model-download attempt $i failed; retrying in $SLEEP seconds" >&2; sleep $SLEEP; done
RUN BACKOFFS="10 20 30 60 90" && for i in 1 2 3 4 5; do HF_TOKEN=$HF_TOKEN comfy model download --url 'https://huggingface.co/Comfy-Org/MiniMax-H3/resolve/main/vae/minimax_h3_video_vae_fp16.safetensors' --relative-path models/vae --filename 'minimax_h3_video_vae_fp16.safetensors' && break; if [ $i -eq 5 ]; then echo "model-download failed after 5 attempts" >&2; exit 1; fi; SLEEP=$(echo $BACKOFFS | cut -d ' ' -f $i) && echo "model-download attempt $i failed; retrying in $SLEEP seconds" >&2; sleep $SLEEP; done
RUN BACKOFFS="10 20 30 60 90" && for i in 1 2 3 4 5; do HF_TOKEN=$HF_TOKEN comfy model download --url 'https://huggingface.co/Comfy-Org/MiniMax-H3/resolve/main/vae/minimax_h3_audio_vae_fp32.safetensors' --relative-path models/vae --filename 'minimax_h3_audio_vae_fp32.safetensors' && break; if [ $i -eq 5 ]; then echo "model-download failed after 5 attempts" >&2; exit 1; fi; SLEEP=$(echo $BACKOFFS | cut -d ' ' -f $i) && echo "model-download attempt $i failed; retrying in $SLEEP seconds" >&2; sleep $SLEEP; done
RUN BACKOFFS="10 20 30 60 90" && for i in 1 2 3 4 5; do HF_TOKEN=$HF_TOKEN comfy model download --url 'https://huggingface.co/lightx2v/Minimax-h3-Turbo/resolve/main/minimax_h3_fl2v_turbo_8step_v1.0_comfyui_bf16.safetensors' --relative-path models/loras --filename 'minimax_h3_fl2v_turbo_8step_v1.0_comfyui_bf16.safetensors' && break; if [ $i -eq 5 ]; then echo "model-download failed after 5 attempts" >&2; exit 1; fi; SLEEP=$(echo $BACKOFFS | cut -d ' ' -f $i) && echo "model-download attempt $i failed; retrying in $SLEEP seconds" >&2; sleep $SLEEP; done

# copy all input data (like images or videos) into comfyui (uncomment and adjust if needed)
# COPY input/ /comfyui/input/
