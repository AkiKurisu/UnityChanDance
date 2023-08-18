using System.Collections.Generic;
using System.Linq;
namespace UnityChanDance.VMD
{
    public class MorphBlendShapePlayer : IMorphPlayer
    {
        private int frameNumber = -1;
        private readonly VMDReader vmdReader;
        private readonly MorphBlendShape morphBlendShape;
        private readonly List<string> morphNames;
        public MorphBlendShapePlayer(MorphBlendShape morphBlendShape, VMDReader vmdReader)
        {
            this.vmdReader = vmdReader;
            this.morphBlendShape = morphBlendShape;
            morphNames = vmdReader.FaceKeyFrameGroups.Keys
                        .Intersect(morphBlendShape.GetMorphNames())
                        .Distinct()
                        .ToList();
        }

        public void Morph(int frameNumber)
        {
            if (this.frameNumber == frameNumber) { return; }
            foreach (string morphName in morphNames)
            {
                VMDReader.FaceKeyFrameGroup faceKeyFrameGroup = vmdReader.FaceKeyFrameGroups[morphName];
                VMD.FaceKeyFrame faceKeyFrame = faceKeyFrameGroup.GetKeyFrame(frameNumber);
                if (faceKeyFrame != null)
                {
                    morphBlendShape.SetMorph(morphName, faceKeyFrame.Weight);
                }
                else if (faceKeyFrameGroup.LastMorphKeyFrame != null && faceKeyFrameGroup.NextMorphKeyFrame != null)
                {
                    float rate =
                        (faceKeyFrameGroup.NextMorphKeyFrame.FrameNumber - frameNumber) * faceKeyFrameGroup.LastMorphKeyFrame.Weight
                        + (frameNumber - faceKeyFrameGroup.LastMorphKeyFrame.FrameNumber) * faceKeyFrameGroup.NextMorphKeyFrame.Weight;
                    rate /= faceKeyFrameGroup.NextMorphKeyFrame.FrameNumber - faceKeyFrameGroup.LastMorphKeyFrame.FrameNumber;
                    morphBlendShape.SetMorph(morphName, rate);
                }
                else if (faceKeyFrameGroup.LastMorphKeyFrame != null && faceKeyFrameGroup.NextMorphKeyFrame == null)
                {
                    morphBlendShape.SetMorph(morphName, faceKeyFrameGroup.LastMorphKeyFrame.Weight);
                }
                //全てがnullになることはないはずだが一応
                else if (faceKeyFrameGroup.LastMorphKeyFrame == null && faceKeyFrameGroup.NextMorphKeyFrame != null)
                {
                    float rate = faceKeyFrameGroup.NextMorphKeyFrame.Weight * (frameNumber / faceKeyFrameGroup.NextMorphKeyFrame.FrameNumber);
                    morphBlendShape.SetMorph(morphName, rate);
                }
            }
            this.frameNumber = frameNumber;
        }
    }
}
