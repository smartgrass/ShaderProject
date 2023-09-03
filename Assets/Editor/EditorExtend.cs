using System.Collections;
using System.Collections.Generic;
using System.IO;
using UnityEditor;
using UnityEngine;

public static class EditorExtend
{
    [MenuItem("Assets/Open By VsCode", false, 2)]
    public static void OpenByVsCode()
    {
        string path = Path.GetFullPath(AssetDatabase.GetAssetPath(Selection.activeObject));
        Debug.Log($"yns {path}");
        EditorUtility.OpenWithDefaultApp(path);
    }
}
