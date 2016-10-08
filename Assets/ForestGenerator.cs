using UnityEngine;
using System.Collections;
using SimpleJSON;

public class ForestGenerator : MonoBehaviour {

	//perhaps pull out into a 'prefabs cache' type class
	public static GameObject treePrefab;

	//runs before start and only once during the lifetime of the script
	void Awake() {
 		treePrefab = Resources.Load<GameObject>("Tree");
 		Debug.Log(treePrefab);
	}

	// Use this for initialization
	void Start () {
		GameObject root = Instantiate(treePrefab, gameObject.transform) as GameObject;
		
		string filePath = "dbegn/llvm";
		TextAsset jsonFile = Resources.Load<TextAsset>(filePath);
		JSONNode jsonData = JSON.Parse(jsonFile.text);
		Debug.Log(jsonData[""]);

		root.GetComponent<TreeGenerator>().Generate("root", jsonData);
	}
	
	// Update is called once per frame
	void Update () {
	
	}


}
