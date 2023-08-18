using UnityEngine;
public class PropActivator : MonoBehaviour, IActivateProps
{
    public void ActivateProps()
    {
        foreach (Transform c in transform) c.gameObject.SetActive(true);
    }
}
