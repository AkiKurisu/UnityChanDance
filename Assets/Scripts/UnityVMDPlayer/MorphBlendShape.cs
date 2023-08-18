using System;
using System.Collections.Generic;
using UnityEngine;
namespace UnityChanDance.VMD
{
    [Serializable]
    public class MorphBlendShape
    {
        [Serializable]
        private class MorphParameter
        {
            [Morph]
            public string morphName;
            public SkinnedMeshRenderer skinnedMeshRenderer;
            public BlendShapeParameter[] blendShapeParameters;
            public void SetWeight(float weight)
            {
                for (int i = 0; i < blendShapeParameters.Length; i++)
                {
                    skinnedMeshRenderer.SetBlendShapeWeight(blendShapeParameters[i].blendShapeIndex, weight);
                }
            }
        }
        [Serializable]
        private class BlendShapeParameter
        {
            public int blendShapeIndex;
        }
        [SerializeField]
        private MorphParameter[] morphParameters;
        private const float MorphAmplifier = 100;
        private readonly Dictionary<string, IList<MorphParameter>> morphMap = new();
        public IEnumerable<string> GetMorphNames()
        {
            return morphMap.Keys;
        }
        public void BuildMorphMap()
        {
            foreach (var morphParameter in morphParameters)
            {
                if (morphMap.TryGetValue(morphParameter.morphName, out IList<MorphParameter> collection))
                {
                    collection.Add(morphParameter);
                }
                else
                {
                    morphMap[morphParameter.morphName] = new List<MorphParameter>() { morphParameter };
                }
            }
        }
        public void SetMorph(string morphName, float weight)
        {
            if (!morphMap.TryGetValue(morphName, out IList<MorphParameter> collection))
            {
                return;
            }
            for (int i = 0; i < collection.Count; i++)
            {
                collection[i].SetWeight(weight * MorphAmplifier);
            }
        }
    }
}
