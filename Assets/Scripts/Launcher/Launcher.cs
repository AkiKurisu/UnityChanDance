using System.IO;
using Newtonsoft.Json;
using UnityChanDance.Core;
using UnityEngine;
namespace UnityChanDance.Launcher
{
    public class Launcher : MonoBehaviour
    {
        private UserConfig userConfig;
        private void Awake()
        {
            userConfig = JsonConvert.DeserializeObject<UserConfig>(File.ReadAllText(GlobalPath.ConfigPath));
        }
        private void Start()
        {
            DanceController.Instance.LoadConfigAsync(userConfig);
        }
    }
}