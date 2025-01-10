#!/usr/bin/env python

"""Define a ROS node to replicate the SAM-6D demo.sh script."""

import contextlib
import subprocess
from pathlib import Path

import rospy


def run_command(cmd):
    """Helper function to run shell commands."""
    try:
        subprocess.check_call(cmd, shell=True)
    except subprocess.CalledProcessError as e:
        rospy.logerr(f"Command '{cmd}' failed with error: {e}")


def main():
    rospy.init_node("sam-6d-demo")

    # Get parameters from the ROS parameter server (paths relative to the sam_6d_ros package)
    output_dir = rospy.get_param("~output_dir", "data/Example/outputs")
    cad_path = rospy.get_param("~cad_path", "data/Example/obj_000005.ply")
    rgb_path = rospy.get_param("~rgb_path", "data/Example/rgb.png")
    depth_path = rospy.get_param("~depth_path", "data/Example/depth.png")
    camera_path = rospy.get_param("~camera_path", "data/Example/camera.json")
    segmentor_model = rospy.get_param("~segmentor_model", "sam")  # Instance segmentation model

    # Step 1: Render CAD templates
    rospy.loginfo("Rendering CAD templates...")
    render_cmd = (
        f"blenderproc run render_custom_templates.py "
        f"--output_dir {output_dir} --cad_path {cad_path}"  # --colorize True
    )
    run_command(render_cmd)

    # Step 2: Run the instance segmentation model
    rospy.loginfo("Running instance segmentation model...")
    segmentation_cmd = (
        f"python ../Instance_Segmentation_Model/run_inference_custom.py "
        f"--segmentor_model {segmentor_model} --output_dir {output_dir} "
        f"--cad_path {cad_path} --rgb_path {rgb_path} --depth_path {depth_path} "
        f"--cam_path {camera_path}"
    )
    run_command(segmentation_cmd)

    # Step 3: Run the pose estimation model
    rospy.loginfo("Running pose estimation model...")
    seg_path = Path(output_dir, "sam6d_results", "detection_ism.json")
    pose_estimation_cmd = (
        f"python ../Pose_Estimation_Model/run_inference_custom.py "
        f"--output_dir {output_dir} --cad_path {cad_path} "
        f"--rgb_path {rgb_path} --depth_path {depth_path} "
        f"--cam_path {camera_path} --seg_path {seg_path}"
    )
    run_command(pose_estimation_cmd)

    rospy.loginfo("SAM-6D demo completed.")
    rospy.spin()


if __name__ == "__main__":
    with contextlib.suppress(rospy.ROSInterruptException):
        main()
