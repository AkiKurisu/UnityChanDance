using UnityEngine;
using UnityChanDance.VMD;
using System.IO;
using UnityEngine.Networking;
using System.Threading.Tasks;
namespace UnityChanDance.Core
{
    public class DanceController : MonoBehaviour
    {
        private static DanceController instance;
        public static DanceController Instance => instance;
        public UserConfig Config { get; private set; }
        [SerializeField]
        private UnityVMDPlayer vmdPlayer;
        [SerializeField]
        private StageDirector stageDirector;
        private void Awake()
        {
            instance = this;
        }
        private void OnDestroy()
        {
            instance = null;
        }
        public async void LoadConfigAsync(UserConfig userConfig)
        {
            Config = userConfig;
            using UnityWebRequest www = UnityWebRequestMultimedia.GetAudioClip(Path.Combine(GlobalPath.UserFolderPath, userConfig.AudioPath), AudioType.WAV);
            www.SendWebRequest();
            while (!www.isDone)
            {
                await Task.Yield();
            }
            var audioClip = DownloadHandlerAudioClip.GetContent(www);
            Debug.Log(Path.Combine(GlobalPath.UserFolderPath, userConfig.VMDPath));
            await vmdPlayer.PlayAsync(Path.Combine(GlobalPath.UserFolderPath, userConfig.VMDPath));
            stageDirector.PlayMusic(audioClip);
        }
    }
}
