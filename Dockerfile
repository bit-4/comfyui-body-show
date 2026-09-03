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
           grep -q "class MiniMaxH3ImageToVideo" /comfyui/comfy_extras/nodes_minimax_h3.py; then \
            echo ">>> MiniMaxH3ImageToVideo source file found and class exists"; \
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

# 清理可能存在的旧缓存
RUN find /comfyui -type d -name "__pycache__" -exec rm -rf {} + 2>/dev/null || true && \
    find /comfyui -name "*.pyc" -delete 2>/dev/null || true

# -------------------------------------------------
# 3. 轻量验证（只检查源文件，不做完整 import）
#    完整节点注册会在 ComfyUI 启动时由 extension 系统完成
# -------------------------------------------------
RUN cd /comfyui && \
    test -f comfy_extras/nodes_minimax_h3.py && \
    grep -q "class MiniMaxH3ImageToVideo" comfy_extras/nodes_minimax_h3.py && \
    grep -q "class MiniMaxH3Extension" comfy_extras/nodes_minimax_h3.py && \
    echo ">>> SUCCESS: MiniMax H3 node source files are present" || \
    (echo "ERROR: MiniMax H3 node source verification failed" && exit 1)

# -------------------------------------------------
# 4. 下载所需模型（带重试）
# -------------------------------------------------
RUN BACKOFFS="10 20 30 60 90" && for i in 1 2 3 4 5; do \
    HF_TOKEN=$HF_TOKEN comfy model download \
      --url 'https://huggingface.co/Comfy-Org/MiniMax-H3/resolve/main/diffusion_models/minimax_h3_fl2va_pruned_int8_convrot.safetensors' \
      --relative-path models/diffusion_models \
      --filename 'minimax_h3_fl2va_pruned_int8_convrot.safetensors' && break; \
    if [ $i -eq 5 ]; then echo "model-download failed after 5 attempts" >&2; exit 1; fi; \
    SLEEP=$(echo $BACKOFFS | cut -d ' ' -f $i) && echo "model-download attempt $i failed; retrying in $SLEEP seconds" >&2; sleep $SLEEP; \
done

RUN BACKOFFS="10 20 30 60 90" && for i in 1 2 3 4 5; do \
    HF_TOKEN=$HF_TOKEN comfy model download \
      --url 'https://huggingface.co/Comfy-Org/MiniMax-H3/resolve/main/text_encoders/qwen3vl_32b_minimax_h3_nvfp4_awq.safetensors' \
      --relative-path models/text_encoders \
      --filename 'qwen3vl_32b_minimax_h3_nvfp4_awq.safetensors' && break; \
    if [ $i -eq 5 ]; then echo "model-download failed after 5 attempts" >&2; exit 1; fi; \
    SLEEP=$(echo $BACKOFFS | cut -d ' ' -f $i) && echo "model-download attempt $i failed; retrying in $SLEEP seconds" >&2; sleep $SLEEP; \
done

RUN BACKOFFS="10 20 30 60 90" && for i in 1 2 3 4 5; do \
    HF_TOKEN=$HF_TOKEN comfy model download \
      --url 'https://huggingface.co/Comfy-Org/MiniMax-H3/resolve/main/vae/minimax_h3_video_vae_fp16.safetensors' \
      --relative-path models/vae \
      --filename 'minimax_h3_video_vae_fp16.safetensors' && break; \
    if [ $i -eq 5 ]; then echo "model-download failed after 5 attempts" >&2; exit 1; fi; \
    SLEEP=$(echo $BACKOFFS | cut -d ' ' -f $i) && echo "model-download attempt $i failed; retrying in $SLEEP seconds" >&2; sleep $SLEEP; \
done

RUN BACKOFFS="10 20 30 60 90" && for i in 1 2 3 4 5; do \
    HF_TOKEN=$HF_TOKEN comfy model download \
      --url 'https://huggingface.co/Comfy-Org/MiniMax-H3/resolve/main/vae/minimax_h3_audio_vae_fp32.safetensors' \
      --relative-path models/vae \
      --filename 'minimax_h3_audio_vae_fp32.safetensors' && break; \
    if [ $i -eq 5 ]; then echo "model-download failed after 5 attempts" >&2; exit 1; fi; \
    SLEEP=$(echo $BACKOFFS | cut -d ' ' -f $i) && echo "model-download attempt $i failed; retrying in $SLEEP seconds" >&2; sleep $SLEEP; \
done

RUN BACKOFFS="10 20 30 60 90" && for i in 1 2 3 4 5; do \
    HF_TOKEN=$HF_TOKEN comfy model download \
      --url 'https://huggingface.co/lightx2v/Minimax-h3-Turbo/resolve/main/minimax_h3_fl2v_turbo_8step_v1.0_comfyui_bf16.safetensors' \
      --relative-path models/loras \
      --filename 'minimax_h3_fl2v_turbo_8step_v1.0_comfyui_bf16.safetensors' && break; \
    if [ $i -eq 5 ]; then echo "model-download failed after 5 attempts" >&2; exit 1; fi; \
    SLEEP=$(echo $BACKOFFS | cut -d ' ' -f $i) && echo "model-download attempt $i failed; retrying in $SLEEP seconds" >&2; sleep $SLEEP; \
done
