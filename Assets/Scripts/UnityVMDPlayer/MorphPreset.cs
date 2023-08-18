using Kurisu.AkiPopup;
namespace UnityChanDance.VMD
{
    public class MorphPreset : PopupSet
    {

    }
    public class MorphAttribute : PopupSelector
    {
        public MorphAttribute() : base(typeof(MorphPreset))
        {

        }
    }
}
