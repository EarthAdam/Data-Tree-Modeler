using UnityEngine;
using System.Collections;
using SimpleJSON;

public class ForestGenerator : MonoBehaviour {

	//perhaps pull out into a 'prefabs cache' type class
	public static Tree treePrefab = Resources.Load<Tree>("Tree.prefab");

	// Use this for initialization
	void Start () {
		Tree root = Instantiate(treePrefab, gameObject.transform) as Tree;
		
		string filePath = "dbgen/sample.json";
		TextAsset jsonFile = Resources.Load<TextAsset>(filePath);
		var jsonData = JSON.Parse(jsonFile.text);

		root.GetComponent<TreeGenerator>().generate(jsonData);
	}
	
	// Update is called once per frame
	void Update () {
	
	}


}
