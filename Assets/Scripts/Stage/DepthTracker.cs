using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;
namespace UnityChanDance.Stage
{
    public class DepthTracker : MonoBehaviour
    {
        [SerializeField]
        private Volume trackVolume;
        [SerializeField]
        private Transform focusPoint;
        [SerializeField, Range(1f, 5f)]
        private float speed = 5;
        private DepthVolumeTracker tracker;
        private void Start()
        {
            tracker = new DepthVolumeTracker(
                trackVolume,
                 focusPoint
            );
        }
        private void Update()
        {
            tracker.Tick(speed * Time.deltaTime);
        }
    }
    public class DepthVolumeTracker
    {
        private readonly Transform camera;
        private readonly Transform focusPoint;
        private readonly DepthOfField depthOfField;
        public DepthVolumeTracker(Volume volume, Transform focusPoint)
        {
            camera = UnityEngine.Camera.main.transform;
            this.focusPoint = focusPoint;
            volume.profile.TryGet<DepthOfField>(out depthOfField);
        }
        public void Tick(float deltaTime)
        {
            var depth = (focusPoint.position - camera.position).magnitude;
            depthOfField.focusDistance.value = Mathf.Lerp(depthOfField.focusDistance.value, depth, deltaTime);
        }
        public void Set(float value)
        {
            depthOfField.focusDistance.value = value;
        }
    }
}
