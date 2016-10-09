using UnityEngine;
using System.Collections;
using SimpleJSON;
using System.Collections.Generic;

public class ForestGenerator : MonoBehaviour {

	//perhaps pull out into a 'prefabs cache' type class
	public static GameObject treePrefab;

	//runs before start and only once during the lifetime of the script
	void Awake() {
 		treePrefab = Resources.Load<GameObject>("Tree");
	}

	// Use this for initialization
	void Start () {
		GameObject root = Instantiate(treePrefab, gameObject.transform) as GameObject;
		
		string filePath = "dbgen/llvm_structure";
		TextAsset jsonFile = Resources.Load<TextAsset>(filePath);
		JSONNode jsonData = JSON.Parse(jsonFile.text);

		root.GetComponent<TreeGenerator>().Generate("root", jsonData, new Stack<Vector3>(), 0, 360);
	}
	
	// Update is called once per frame
	void Update () {
	
	}


}
