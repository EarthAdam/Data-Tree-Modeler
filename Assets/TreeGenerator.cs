using UnityEngine;
using System.Collections;

public class TreeGenerator : MonoBehaviour {

	JSONClass files;
	JSONClass directories;

	// Use this for initialization
	void Start () {
	
	}

	void Generate(string name, JSONClass jsonData) {
		files = jsonData["files"];
		directories = jsonData["directories"];

		foreach(KeyValuePair kv in directories) {
			Tree branch = Instantiate(ForestGenerator.treePrefab, gameObject.transform) as Tree;
			branch.GetComponent<TreeGenerator>().generate(kv.Key, kv.Value); //send the folder name and subdirectories
		}
	}

	static void 
	
	// Update is called once per frame
	void Update () {
	
	}
}
