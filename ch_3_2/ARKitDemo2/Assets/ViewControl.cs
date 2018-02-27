using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.XR.iOS;


public class ViewControl : MonoBehaviour {

	// 声明2个模型，分别是精灵球和魔法球
	public GameObject spriteBallObj;
	public GameObject magicBallObj;

	// 声明3个2D纹理，作为背景图片使用
	public Texture2D magicTexture;
	public Texture2D findTexture;
	public Texture2D fontTexture;

	private UnityARSessionNativeInterface m_session;
	private int scoreNum;
	private string tipStr;
	private GameObject magicBall;
	private GameObject spriteBall;

	void Start () {
		// 获取会话
		m_session = UnityARSessionNativeInterface.GetARSessionNativeInterface ();
		scoreNum = 0;
		tipStr = "Hello Game!";
	}

	void Update () {

		if(magicBall){

			// 持续移动
			var translation = Time.deltaTime * 10;
			magicBall.transform.Translate (Vector3.forward * translation, Camera.main.transform);
		}
	}

	bool getRandomValue(){
	
		// 获取随机结果
		int randomNum = Random.Range (0, 100);

		if (randomNum > 50) {
			return true;
		} else {
			return false;
		}
	}


	IEnumerator WaitAndRunWithSecond(float waitSecond)  
	{  
		yield return new WaitForSeconds(waitSecond);  
		//等待waitTime秒要执行的动作  
		if(magicBall){
			DestroyObject(magicBall); 
		}
	} 

	void OnCollisionEnter(Collision collisionInfo){
		
		DestroyObject(spriteBall); 

		tipStr = "捕捉成功，分数+1！";
		scoreNum += 1;
	}

	void OnGUI (){
	
		var screenW = Screen.width;
		var screenH = Screen.height;

		if(GUI.Button (new Rect((screenW-200)/2, screenH-250, 200, 200), magicTexture)){

			magicBall = GameObject.Instantiate (magicBallObj);
			magicBall.transform.position = Camera.main.transform.position;
			magicBall.transform.rotation = Camera.main.transform.rotation;

			StartCoroutine (WaitAndRunWithSecond (2));
		}

		if(GUI.Button (new Rect(screenW-190, screenH-200, 170, 170), findTexture)){

			DestroyObject(spriteBall); 

			if (getRandomValue ()) {
			
				// 从屏幕中心发送射线
				Vector3 shootPos = Camera.main.ScreenToViewportPoint (new Vector3 (screenW / 2, screenH / 2));
				ARPoint shootPoint = new ARPoint { 
					x = shootPos.x,
					y = shootPos.y,
				};

				// 开始命中测试，类型为利用现有的平面的范围
				List<ARHitTestResult> results = m_session.HitTest (shootPoint, ARHitTestResultType.ARHitTestResultTypeExistingPlaneUsingExtent);
				if (results.Count > 0) {
					tipStr = "已找到精灵球！";
					// 创建一个对象，并根据结果初始化对象的位姿
					spriteBall = GameObject.Instantiate (spriteBallObj);
					spriteBall.transform.position = UnityARMatrixOps.GetPosition (results [0].worldTransform);
					spriteBall.transform.rotation = UnityARMatrixOps.GetRotation (results [0].worldTransform);
				}
			} else {
				tipStr = "未找到精灵球，请再尝试！";
			}
		}

		// 显示分数
		GUIStyle scoreStyle = new GUIStyle ();
		scoreStyle.normal.background = fontTexture;
		scoreStyle.alignment = TextAnchor.MiddleCenter;
		scoreStyle.fontSize = 120;
		GUI.Label(new Rect(20, screenH-200, 170, 170), scoreNum.ToString(),scoreStyle);

		// 显示提示信息
		GUIStyle tipStyle = new GUIStyle ();
		tipStyle.normal.background = fontTexture;
		tipStyle.alignment = TextAnchor.MiddleCenter;
		tipStyle.fontSize = 30;
		GUI.Label (new Rect (50, 50, screenW - 100, 100), tipStr, tipStyle);
	}
}

//					spriteBall.transform.LookAt (new Vector3 (Camera.main.transform.position.x, spriteBall.transform.position.y, Camera.main.transform.position.z));
