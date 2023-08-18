using System.Collections.Generic;
using UnityEngine;
namespace Reaktion
{
    public class PoolManager : MonoBehaviour
    {
        public static PoolManager Instance
        {
            get
            {
                if (instance == null)
                {
                    GameObject managerObject = new GameObject { name = "PoolManager" };
                    instance = managerObject.AddComponent<PoolManager>();
                }
                return instance;
            }
        }
        private static PoolManager instance;
        public Dictionary<string, GameObjectPoolData> gameObjectPoolDic = new();
        private void OnDestroy()
        {
            if (instance == this) instance = null;
            Clear();
        }

        public GameObject GetGameObject(string assetName, Transform parent = null)
        {
            GameObject obj = null;
            // 检查有没有这一层
            if (gameObjectPoolDic.TryGetValue(assetName, out GameObjectPoolData poolData) && poolData.poolQueue.Count > 0)
            {
                obj = poolData.GetObj(parent);
            }
            return obj;
        }

        public void PushGameObject(GameObject obj, string overrideName = null)
        {
            string name = overrideName ?? obj.name;
            // 现在有没有这一层
            if (gameObjectPoolDic.TryGetValue(name, out GameObjectPoolData poolData))
            {
                poolData.PushObj(obj);
            }
            else
            {
                gameObjectPoolDic.Add(name, new GameObjectPoolData(obj, gameObject));
            }
        }
        public void Clear()
        {

            for (int i = 0; i < transform.childCount; i++)
            {
                Destroy(transform.GetChild(i).gameObject);
            }
            gameObjectPoolDic.Clear();
        }
        public void ClearGameObject(string prefabName)
        {
            GameObject go = transform.Find(prefabName).gameObject;
            if (go != null)
            {
                Destroy(go);
                gameObjectPoolDic.Remove(prefabName);

            }

        }
        public void ClearGameObject(GameObject prefab)
        {
            ClearGameObject(prefab.name);
        }

    }
    public static class ObjectPoolExtension
    {
        public static void GameObjectPushPool(this GameObject go, string overrideName = null)
        {
            PoolManager.Instance.PushGameObject(go, overrideName);
        }
        public static void GameObjectPushPool(this Component com, string overrideName = null)
        {
            GameObjectPushPool(com.gameObject, overrideName);
        }

    }
}