using UnityEngine;
using System.Collections;

public class ForestGenerator : MonoBehaviour {

	// Use this for initialization
	void Start () {
		String filePath = "dbgen/sample.json";
		TextAsset targetFile = Resources.Load<TextAsset>(filePath);
		GameObject tree = Instantiate(tree, gameObject.transform) as GameObject;
	}
	
	// Update is called once per frame
	void Update () {
	
	}
}
