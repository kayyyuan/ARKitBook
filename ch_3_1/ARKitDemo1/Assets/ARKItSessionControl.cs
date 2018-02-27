using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.XR.iOS;

public class ARKItSessionControl : MonoBehaviour {

	private UnityARSessionNativeInterface m_session;
	// Use this for initialization
	void Start () {

		m_session = UnityARSessionNativeInterface.GetARSessionNativeInterface ();
		
	}
		
	// Update is called once per frame
	void Update () {
		
	}

	void OnGUI(){

		// 创建暂停按钮
		if (GUI.Button (new Rect (50, 50, 100, 50), "会话暂停")) {
			// 会话暂停
			m_session.Pause ();
		}

		// 创建开始按钮
		if (GUI.Button (new Rect (100, 200, 100, 50), "会话开始")) {
			// 新建世界跟踪配置类
			ARKitWorldTrackingSessionConfiguration config = new ARKitWorldTrackingSessionConfiguration ();
			config.alignment = UnityARAlignment.UnityARAlignmentGravity;
			config.planeDetection = UnityARPlaneDetection.Horizontal;
			config.enableLightEstimation = true;
			config.getPointCloudData = true;
			// 重置会话
			m_session.RunWithConfigAndOptions (config, UnityARSessionRunOption.ARSessionRunOptionRemoveExistingAnchors);
		}
	}
}
