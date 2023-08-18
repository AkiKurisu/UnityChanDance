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
    public GameObject mainCameraRigPrefab;
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
    void Awake()
    {
        // Instantiate the prefabs.
        musicPlayer = Instantiate(musicPlayerPrefab);

        var cameraRig = Instantiate(mainCameraRigPrefab);
        mainCameraSwitcher = cameraRig.GetComponentInChildren<CameraSwitcher>();
        screenOverlays = cameraRig.GetComponentsInChildren<ScreenOverlay>();

        for (var i = 0; i < prefabsNeedsActivation.Length; i++)
            props.AddRange(Instantiate(prefabsNeedsActivation[i]).GetComponentsInChildren<IActivateProps>());
        foreach (var p in miscPrefabs) Instantiate(p);
    }
    private void Update()
    {
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
        if (mainCameraSwitcher)
            mainCameraSwitcher.ChangePosition(cameraPoints[index], true);
    }

    public void StartAutoCameraChange()
    {
        if (mainCameraSwitcher)
            mainCameraSwitcher.StartAutoChange();
    }

    public void StopAutoCameraChange()
    {
        if (mainCameraSwitcher)
            mainCameraSwitcher.StopAutoChange();
    }
}
