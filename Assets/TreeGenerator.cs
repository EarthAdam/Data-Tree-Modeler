using UnityEngine;
using System.Collections;
using System.Collections.Generic;
using SimpleJSON;

public class TreeGenerator : MonoBehaviour {

	JSONClass nodes;

	int defaultHeight = 2;

	int magnitude = 10;
	Vector3 dir = Vector3.up;

	Transform childTransform;

	float minAngle;
	float maxAngle;

	// Use this for initialization
	void Start () {
		childTransform = gameObject.transform.GetChild(0);
		//childPrim.setActive(false); //should be disabled in prefab anyway but kept here for safety
		Vector3 target = dir * magnitude;
		childTransform.position = Vector3.Lerp(gameObject.transform.position, target, 0.5f);
		childTransform.localScale = new Vector3(1, magnitude / defaultHeight, 1);
		Debug.Log(target);
	}

	public void Generate(string name, JSONNode jsonData, float minAngle, float maxAngle) {
		gameObject.name = name;
		this.minAngle = minAngle;
		this.maxAngle = maxAngle;

		nodes = jsonData["nodes"] as JSONClass;

		StartCoroutine("SpawnChildren");
	}
	
	// Update is called once per frame
	void Update () {
	
	}

	IEnumerator SpawnChildren() {
		int segments = nodes.Count + 1;
		float stepAngle = (maxAngle - minAngle) / segments;                  
		float currAngle = minAngle + (stepAngle / 2);
		foreach(KeyValuePair<string, JSONNode> kv in nodes) {
			GameObject branch = Instantiate(ForestGenerator.treePrefab, gameObject.transform) as GameObject;
			branch.transform.localPosition = dir * magnitude;
			branch.GetComponent<TreeGenerator>().Generate(kv.Key, kv.Value, currAngle, currAngle + stepAngle); //send the folder name and subdirectories
			currAngle += stepAngle;
			yield return new WaitForSeconds(1f); //new WaitForSeconds(.1f)
		}
	}
}
