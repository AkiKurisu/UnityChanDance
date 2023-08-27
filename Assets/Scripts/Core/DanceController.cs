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
        private UnityVMDCamera vmdCamera;
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
            if (!string.IsNullOrEmpty(userConfig.CameraPath))
            {
                stageDirector.StopAutoCameraChange();
                stageDirector.UseBuiltInCameraAnimation = false;
                await vmdCamera.InitAsync(Path.Combine(GlobalPath.UserFolderPath, userConfig.CameraPath));
                await vmdPlayer.PlayAsync(Path.Combine(GlobalPath.UserFolderPath, userConfig.VMDPath));
            }
            else
            {
                await vmdPlayer.PlayAsync(Path.Combine(GlobalPath.UserFolderPath, userConfig.VMDPath));
            }
            stageDirector.PlayMusic(audioClip);
        }
    }
}
