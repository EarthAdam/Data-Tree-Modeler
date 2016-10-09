using UnityEngine;
using System.Collections;

public class DrawLine4 : MonoBehaviour {
	private LineRenderer lineRenderer;
	private float counter;
	private float[] dist = new float[4];
	private int levels = 4;

	private Vector3[] points = new Vector3[4];


	public float lineDrawSpeed = 6f;

	// Use this for initialization
	void Start () {
		points[0] = new Vector3(-0.1f,0,0.1f);
		points[1] = new Vector3(-0.1f,3,0.1f);
		points[2] = new Vector3(-1,4,1);
		points[3] = new Vector3(-2,5,2.51f);
		lineRenderer = GetComponent<LineRenderer>();
		lineRenderer.SetPosition(0,points[0]);
        lineRenderer.SetWidth(0.15f,0.05f);

		for (int i = 1;i<levels;i++){
			dist[i] = Vector3.Distance(points[i-1], points[i]);
		}

	}
	
	// Update is called once per frame
	void Update () {
		counter += 0.1f/lineDrawSpeed;
		if (counter<dist[1])
		{
			float x = Mathf.Lerp(0,dist[1],counter);
			Vector3 pointAlongLine = x * Vector3.Normalize((points[1]-points[0])+points[0]);
			lineRenderer.SetPosition(1, pointAlongLine);
			lineRenderer.SetPosition(2, pointAlongLine);
			lineRenderer.SetPosition(3, pointAlongLine);
        }
		else if (counter<(dist[1]+dist[2]))
		{
			float x = Mathf.Lerp(dist[1],(dist[1]+dist[2]),counter-dist[1]);
			Vector3 pointAlongLine = x * Vector3.Normalize((points[2]-points[1])+points[1]);
			lineRenderer.SetPosition(2, pointAlongLine);
			lineRenderer.SetPosition(3, pointAlongLine);
		}
		else if (counter<(dist[1]+dist[2]+dist[3]))
		{
			float x = Mathf.Lerp((dist[1] + dist[2]), (dist[1]+dist[2]+dist[3]),counter-(dist[1]+dist[2]));
			Vector3 pointAlongLine = x * Vector3.Normalize((points[3]-points[2])+points[2]);
			lineRenderer.SetPosition(3, pointAlongLine);
			
		}


	}
}
