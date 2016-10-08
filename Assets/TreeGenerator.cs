using UnityEngine;
using System.Collections;
using System.Collections.Generic;
using SimpleJSON;

public class TreeGenerator : MonoBehaviour {

	JSONClass files;
	JSONClass directories;

	// Use this for initialization
	void Start () {
	
	}

	public void Generate(string name, JSONNode jsonData) {
		files = jsonData["files"] as JSONClass;
		directories = jsonData["directories"] as JSONClass;

		foreach(KeyValuePair<string, JSONNode> kv in directories) {
			Tree branch = Instantiate(ForestGenerator.treePrefab, gameObject.transform) as Tree;
			branch.GetComponent<TreeGenerator>().Generate(kv.Key, kv.Value); //send the folder name and subdirectories
		}
	}
	
	// Update is called once per frame
	void Update () {
	
	}
}
