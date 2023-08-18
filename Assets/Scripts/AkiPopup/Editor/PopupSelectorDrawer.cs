using UnityEngine;
using UnityEditor;
using System;
using System.Collections.Generic;
namespace Kurisu.AkiPopup.Editor
{
    [CustomPropertyDrawer(typeof(PopupSelector),true)]
    public class PopupSelectorDrawer : PropertyDrawer
    {
        private static readonly GUIContent k_IsNotStringLabel = new GUIContent("The property type is not string.");
        private static readonly GUIContent k_IsNotPopupSetLabel = new GUIContent("The popup type is not implemented form PopupSet.");
        private static readonly Dictionary<Type,PopupSet> dataSetDict=new Dictionary<Type, PopupSet>();
        public override void OnGUI(Rect position, SerializedProperty property, GUIContent label)
        {
            EditorGUI.BeginProperty(position,label,property);
            var popupType=(attribute as PopupSelector).PopupType;
            var title=(attribute as PopupSelector).PopupTitle;
            if(popupType.IsSubclassOf(typeof(PopupSet))||popupType==typeof(PopupSet))
            {
                if (property.propertyType == SerializedPropertyType.String) {
                Rect popupPosition = new Rect(position);
                popupPosition.height = EditorGUIUtility.singleLineHeight;
                if(!dataSetDict.ContainsKey(popupType))dataSetDict[popupType]=PopupSet.GetOrCreateSettings(popupType);
                PopupSet popupSet=dataSetDict[popupType];
                int index=EditorGUI.Popup(position:popupPosition,title??label.text,selectedIndex:popupSet.GetStateID(property.stringValue),displayedOptions:popupSet.Values);
                if(index>=0)
                {
                    property.stringValue=popupSet.Values[index];
                }
                }
                else 
                {
                    EditorGUI.LabelField(position,label,k_IsNotStringLabel);
                }
            }
            else
            {
                EditorGUI.LabelField(position,label,k_IsNotPopupSetLabel);
            }
            
            EditorGUI.EndProperty();
        }
    }
}
