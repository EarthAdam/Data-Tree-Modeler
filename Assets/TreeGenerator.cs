using UnityEngine;
using System.Collections;
using System.Collections.Generic;
using SimpleJSON;

public class TreeGenerator : MonoBehaviour {

	int defaultHeight = 2;

	float magnitude = 10;
	Vector3 dir = new Vector3(Random.Range(0, 1), Random.Range(0, 1), Random.Range(0, 1));

	Transform childTransform;

	Stack<Vector3> path;
	float minAngle;
	float maxAngle;
	float angle;
	JSONClass nodes;

	// Use this for initialization
	void Start () {
		childTransform = gameObject.transform.GetChild(0);
		//childPrim.setActive(false); //should be disabled in prefab anyway but kept here for safety
		Vector3 target = dir * magnitude;
		childTransform.position = Vector3.Lerp(gameObject.transform.position, target, 0.5f);
		childTransform.localScale = new Vector3(1, magnitude / defaultHeight, 1);
		Debug.Log(target);
	}

	public void Generate(string name, JSONNode jsonData, Stack<Vector3> path, float minAngle, float maxAngle) {
		gameObject.name = name;
		this.path = path;
		this.minAngle = minAngle;
		this.maxAngle = maxAngle;
		this.angle = (minAngle + maxAngle) / 2;

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
			Stack<Vector3> clone = new Stack<Vector3>(path);
			GameObject branch = Instantiate(ForestGenerator.treePrefab, gameObject.transform) as GameObject;
			
			Vector3 moveVector = dir * magnitude;
			Vector3 nextVector = clone.Peek() + moveVector;
			branch.transform.localPosition = moveVector;
			branch.GetComponent<TreeGenerator>().Generate(kv.Key, kv.Value, currAngle, currAngle + stepAngle); //send the folder name and subdirectories
			currAngle += stepAngle;
			yield return new WaitForSeconds(0.5f); //new WaitForSeconds(.1f)
		}
	}
}
