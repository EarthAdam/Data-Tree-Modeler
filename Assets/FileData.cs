using UnityEngine;
using System.Collections;
using System.IO;

public class FileData {
    public string fileName;
    public long fileSize;

	public FileData(string file) {
		fileName = file;
		fileSize = new System.IO.FileInfo(file).Length;
	}
}
