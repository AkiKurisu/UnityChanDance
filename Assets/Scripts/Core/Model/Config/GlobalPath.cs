using System.IO;
using UnityEngine;
namespace UnityChanDance.Core
{
    public class GlobalPath
    {
#if !UNITY_EDITOR && UNITY_ANDROID
        public static string UserFolderPath = Path.Combine(Application.persistentDataPath, "VMD");
#else
        public static string UserFolderPath = Path.Combine(Application.dataPath, "VMD");
#endif
#if !UNITY_EDITOR && UNITY_ANDROID
        public static string ConfigPath = Path.Combine(Application.persistentDataPath, "UserConfig.json");
#else
        public static string ConfigPath = Path.Combine(Application.dataPath, "UserConfig.json");
#endif
    }
}
