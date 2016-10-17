using UnityEngine;
using System.Collections;

public class DirectoryList {
    public string directoryName;
    public long directorySize;
    public DirectoryList [] listOfDirectories;
    public FileData [] listOfFiles;

	public DirectoryList(string directory, long size,  DirectoryList [] directories, FileData [] files) {
		directoryName = directory;
		directorySize = size;
    	listOfDirectories = directories;
    	listOfFiles = files;
	}
}
