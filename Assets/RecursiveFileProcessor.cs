// For Directory.GetFiles and Directory.GetDirectories
// For File.Exists, Directory.Exists
using System;
using System.IO;
using System.Collections;
using UnityEngine;
using System.Collections;

public class RecursiveFileProcessor : MonoBehaviour {
    void Start()
    {
        print("FILES:::");	
        string path = "C:\\Users\\Adam\\Desktop\\test";
        if(System.IO.Directory.Exists(path)) 
        {
            // This path is a directory
            print("WORKING MAYBE???");
            print(ProcessDirectory(path).directorySize);
        }
        else 
        {
            Console.WriteLine("{0} is not a valid directory.", path);
        }     
    }


    // Process all files in the directory passed in, recurse on any directories 
    // that are found, and process the files they contain.
    DirectoryList ProcessDirectory(string targetDirectory) 
    {
        // Process the list of files found in the directory.
        string [] fileEntries = Directory.GetFiles(targetDirectory);
        FileData [] listOfFiles = new FileData[fileEntries.Length];
        long directorySize = 0;
        FileData currentFile;
        for (int i = 0; i < fileEntries.Length; i++) {
            currentFile = ProcessFile(fileEntries[i]);
            listOfFiles[i] = currentFile;
            directorySize = directorySize + currentFile.fileSize;
        }

        // Recurse into subdirectories of this directory.
        string [] subdirectoryEntries = Directory.GetDirectories(targetDirectory);
        DirectoryList [] listOfDirectories = new DirectoryList[subdirectoryEntries.Length];
        DirectoryList currentDirectory;
        for (int i = 0; i < subdirectoryEntries.Length; i++) {
            currentDirectory = ProcessDirectory(subdirectoryEntries[i]);
            listOfDirectories[0] = currentDirectory;
            directorySize = directorySize + currentDirectory.directorySize;
        }
        return new DirectoryList(targetDirectory, directorySize,  listOfDirectories, listOfFiles);
    }

    // Insert logic for processing found files here.
    FileData ProcessFile(string path) 
    {
    	FileData file = new FileData(path);
        print(file.fileName);	
        print(file.fileSize); 
        return file;  
    }
}