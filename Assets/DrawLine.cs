using UnityEngine;
using System.Collections;

public class DrawLine : MonoBehaviour {
	private LineRenderer lineRenderer;
	private float counter;
	private float[] dist = new float[4];
	private int levels = 4;

	private Vector3[] points = new Vector3[4];


	public float lineDrawSpeed = 6f;

	// Use this for initialization
	void Start () {
		points[0] = new Vector3(0,0,0);
		points[1] = new Vector3(0,3,0);
		points[2] = new Vector3(-1,5,0);
		points[3] = new Vector3(-2,6,1);
		lineRenderer = GetComponent<LineRenderer>();
		lineRenderer.SetPosition(0, points[0]);
		lineRenderer.SetWidth(0.55f,0.45f);

		dist[0] = 0;
		for (int i = 1;i<levels;i++){
			dist[i] = Vector3.Distance(points[i-1], points[i]);
		}

	}
	
	// Update is called once per frame
	void Update () {
		counter += 0.1f/lineDrawSpeed;
		for(int i =1;i<=levels;i++){
			float x = Mathf.Lerp(dist[i-1],dist[i],counter);
			Vector3 pointAlongLine = x * Vector3.Normalize(points[i]-points[i-1])+points[i-1];
			lineRenderer.SetPosition(i, pointAlongLine);
		}

	}
}
