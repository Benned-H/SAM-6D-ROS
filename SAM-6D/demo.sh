# Render CAD templates
cd Render
blenderproc run render_custom_templates.py --output_dir $OUTPUT_DIR --cad_path $CAD_PATH #--colorize True 


# Run manually from `SAM-6D` folder:
blenderproc run Render/render_custom_templates.py --output_dir Data/Example/outputs --cad_path Data/Example/obj_000005.ply #--colorize True 


# Run instance segmentation model
export SEGMENTOR_MODEL=sam

cd ../Instance_Segmentation_Model
python run_inference_custom.py --segmentor_model $SEGMENTOR_MODEL --output_dir $OUTPUT_DIR --cad_path $CAD_PATH --rgb_path $RGB_PATH --depth_path $DEPTH_PATH --cam_path $CAMERA_PATH


# Run manually from within Instance_Segmentation_Model:
python run_inference_custom.py --segmentor_model sam --output_dir ../Data/Example/outputs --cad_path ../Data/Example/obj_000005.ply --rgb_path ../Data/Example/rgb.png --depth_path ../Data/Example/depth.png --cam_path ../Data/Example/camera.json

# Fun new error: xFormers wasn't build with CUDA support

# Run pose estimation model
export SEG_PATH=$OUTPUT_DIR/sam6d_results/detection_ism.json

cd ../Pose_Estimation_Model
python run_inference_custom.py --output_dir $OUTPUT_DIR --cad_path $CAD_PATH --rgb_path $RGB_PATH --depth_path $DEPTH_PATH --cam_path $CAMERA_PATH --seg_path $SEG_PATH
