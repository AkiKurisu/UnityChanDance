using System.Collections.Generic;
using UnityEngine;
namespace Reaktion
{
    public class GameObjectPoolData
    {
        public GameObject fatherObj;
        public Queue<GameObject> poolQueue;

        public GameObjectPoolData(GameObject obj, GameObject poolRootObj)
        {
            fatherObj = new GameObject(obj.name);
            fatherObj.transform.SetParent(poolRootObj.transform);
            poolQueue = new Queue<GameObject>();
            PushObj(obj);
        }

        public void PushObj(GameObject obj)
        {

            poolQueue.Enqueue(obj);

            obj.transform.SetParent(fatherObj.transform);

            obj.SetActive(false);
        }

        public GameObject GetObj(Transform parent = null)
        {
            GameObject obj = poolQueue.Dequeue();

            obj.SetActive(true);
            obj.transform.SetParent(parent);
            return obj;
        }
    }

}