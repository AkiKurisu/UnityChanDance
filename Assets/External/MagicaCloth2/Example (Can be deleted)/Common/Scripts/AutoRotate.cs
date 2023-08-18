// Magica Cloth 2.
// Copyright (c) 2023 MagicaSoft.
// https://magicasoft.jp
using UnityEngine;

namespace MagicaCloth2
{
    public class AutoRotate : MonoBehaviour
    {
        public Vector3 eulers = new Vector3(0, 90, 0);
        public Space space = Space.World;

        [SerializeField]
        [Range(0.1f, 5.0f)]
        private float interval = 2.0f;

        public bool useSin = true;


        private float time = 0;

        void Update()
        {
            if (useSin)
            {
                time += Time.deltaTime;
                float ang = (time % interval) / interval * Mathf.PI * 2.0f;
                var t = Mathf.Sin(ang);
                if (space == Space.World)
                    transform.eulerAngles = eulers * t;
                else
                    transform.localEulerAngles = eulers * t;
            }
            else
            {
                transform.Rotate(eulers * Time.deltaTime, space);
            }
        }
    }

}
