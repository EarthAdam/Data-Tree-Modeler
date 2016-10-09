using UnityEngine;
using System.Collections;
using System.Collections.Generic;
using SimpleJSON;

public class TreeGenerator : MonoBehaviour {

	JSONClass nodes;

	// Use this for initialization
	void Start () {
	
	}

	public void Generate(string name, JSONNode jsonData) {
		gameObject.name = name;

		nodes = jsonData["nodes"] as JSONClass;


	}
	
	// Update is called once per frame
	void Update () {
	
	}

	void spawnChildren() {
		foreach(KeyValuePair<string, JSONNode> kv in nodes) {
			GameObject branch = Instantiate(ForestGenerator.treePrefab, gameObject.transform) as GameObject;
			branch.GetComponent<TreeGenerator>().Generate(kv.Key, kv.Value); //send the folder name and subdirectories
		}
	}
}
