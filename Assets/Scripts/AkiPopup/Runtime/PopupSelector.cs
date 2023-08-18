using System;
using UnityEngine;
namespace Kurisu.AkiPopup
{
    [AttributeUsage(AttributeTargets.Field,AllowMultiple = false)]
    public class PopupSelector : PropertyAttribute {
        private readonly Type mType;
        private readonly string mTitle;
        public PopupSelector(Type type)
        {
            this.mType=type;
        }
        public PopupSelector(Type type,string title)
        {
            this.mType=type;
            this.mTitle=title;
        }
        public PopupSelector()
        {
            this.mType=typeof(PopupSet);
        }
        public PopupSelector(string title)
        {
            this.mType=typeof(PopupSet);
            this.mTitle=title;
        }
        public Type PopupType=>mType;
        public string PopupTitle=>mTitle;
    }
}