using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.XR.iOS;

public class ARKItHitTestControl : MonoBehaviour {

	public GameObject obj;
	private UnityARSessionNativeInterface m_session;

	// Use this for initialization
	void Start () {
		m_session = UnityARSessionNativeInterface.GetARSessionNativeInterface ();
	}
	
	// Update is called once per frame
	void Update () {
		if (Input.touchCount > 0) {
			if (Input.GetTouch (0).phase == TouchPhase.Began) {
				StartHitTest();
			}
		}
	}

	void StartHitTest()
	{
		// 生成ARPoint类型的点击坐标
		Vector3 tapPos = Camera.main.ScreenToViewportPoint (Input.GetTouch (0).position);
		ARPoint tapPoint = new ARPoint {
			x = tapPos.x,
			y = tapPos.y,
		};

		// 开始命中测试，类型为利用现有的平面的范围
		List<ARHitTestResult> results = m_session.HitTest (tapPoint, ARHitTestResultType.ARHitTestResultTypeExistingPlaneUsingExtent);
		if (results.Count > 0) {
			// 创建一个对象，并根据结果初始化对象的位姿
			GameObject newObj = GameObject.Instantiate (obj);
			newObj.transform.position = UnityARMatrixOps.GetPosition (results [0].worldTransform);
			newObj.transform.rotation = UnityARMatrixOps.GetRotation (results [0].worldTransform);
			newObj.transform.LookAt (new Vector3 (Camera.main.transform.position.x, newObj.transform.position.y, Camera.main.transform.position.z));
		}
	}
}
