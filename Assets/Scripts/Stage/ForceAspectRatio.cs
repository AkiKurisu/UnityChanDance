using UnityEngine;
[ExecuteInEditMode]
public class ForceAspectRatio : MonoBehaviour
{
    public float horizontal = 16;
    public float vertical = 9;
    private Camera _camera;
    private void Awake()
    {
        _camera = GetComponent<Camera>();
    }
    private void Update()
    {
        _camera.aspect = horizontal / vertical;
    }
}
