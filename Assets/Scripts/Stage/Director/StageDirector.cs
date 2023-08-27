using System.Collections.Generic;
using UnityEngine;
public interface IActivateProps
{
    void ActivateProps();
}
public class StageDirector : MonoBehaviour
{
    // Prefabs.
    public GameObject musicPlayerPrefab;
    [SerializeField]
    private GameObject cameraRig;
    public GameObject[] prefabsNeedsActivation;
    public GameObject[] miscPrefabs;

    // Camera points.
    public Transform[] cameraPoints;

    // Exposed to animator.
    public float overlayIntensity = 1.0f;

    // Objects to be controlled.
    private GameObject musicPlayer;
    CameraSwitcher mainCameraSwitcher;
    ScreenOverlay[] screenOverlays;
    private readonly List<IActivateProps> props = new();
    [field: SerializeField]
    public bool UseBuiltInCameraAnimation { get; set; } = true;
    void Awake()
    {
        // Instantiate the prefabs.
        musicPlayer = Instantiate(musicPlayerPrefab);
        mainCameraSwitcher = cameraRig.GetComponentInChildren<CameraSwitcher>();
        screenOverlays = cameraRig.GetComponentsInChildren<ScreenOverlay>();

        for (var i = 0; i < prefabsNeedsActivation.Length; i++)
            props.AddRange(Instantiate(prefabsNeedsActivation[i]).GetComponentsInChildren<IActivateProps>());
        foreach (var p in miscPrefabs) Instantiate(p);
    }
    private void Update()
    {
        if (UseBuiltInCameraAnimation) mainCameraSwitcher?.Tick();
        foreach (var so in screenOverlays)
        {
            so.intensity = overlayIntensity;
            so.enabled = overlayIntensity > 0.01f;
        }
    }

    public void PlayMusic(AudioClip audioClip)
    {
        foreach (var source in musicPlayer.GetComponentsInChildren<AudioSource>())
        {
            source.clip = audioClip;
            source.Play();
        }
    }

    public void ActivateProps()
    {
        foreach (var o in props) o.ActivateProps();
    }

    public void SwitchCamera(int index)
    {
        if (UseBuiltInCameraAnimation)
            mainCameraSwitcher?.ChangePosition(cameraPoints[index], true);
    }

    public void StartAutoCameraChange()
    {
        if (UseBuiltInCameraAnimation)
            mainCameraSwitcher?.StartAutoChange();
    }

    public void StopAutoCameraChange()
    {
        mainCameraSwitcher?.StopAutoChange();
    }
}
