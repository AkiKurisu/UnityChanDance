using System.IO;
using System.Runtime.InteropServices;
using System.Threading.Tasks;
using Cinemachine;
using UnityEngine;
namespace UnityChanDance.VMD
{
    public class UnityVMDCamera : MonoBehaviour
    {
        public GameObject CameraCenter;  //カメラ中心
        public CinemachineVirtualCamera virtualCamera;        //カメラ
        private bool success = false;    //データの準備完了フラグ
        public bool IsPlaying { get; private set; }
        public event System.Action OnStop;
        private CameraData[] Cam_m;
        private int t = 0;
        private float t_f = 0.0f;
        [SerializeField]
        private UnityVMDPlayer player;
        [SerializeField]
        private Animator animator;
        [SerializeField]
        private float distanceMulti = 12.5f;
        [SerializeField]
        private bool enableFieldOfView = true;
        private float nowframe = 0;
        private const int HEADER = 50;            //ヘッダーの桁数
        private const int MOTIONCOUNT = 4;        //モーションレコード数
        private const int SKINCOUNT = 4;          //スキンレコード数

        [StructLayout(LayoutKind.Explicit)]
        public struct Union
        {
            [FieldOffset(0)]
            public float float0;

            [FieldOffset(0)]
            public int int0;
        }

        //カメラ情報
        public struct CameraData
        {
            public int frame;       //対象フレーム
            public float distans;   //距離

            public float Pos_x;     //カメラ中心のx座標
            public float Pos_y;     //カメラ中心のy座標
            public float Pos_z;     //カメラ中心のz座標

            public float Rot_x;     //カメラ中心のx軸回転
            public float Rot_y;     //カメラ中心のy軸回転
            public float Rot_z;     //カメラ中心のz軸回転

            public float viewAngle; //視野角

            public int[] Bezier;    //ベジェ曲線の補間パラメータ
            public bool originalframe;
        }
        // Use this for initialization
        public bool Init(Animator animator, TextAsset textAsset)
        {
            this.animator = animator;
            return Init(textAsset.bytes);
        }
        public async Task<bool> InitAsync(string filePath)
        {
            return Init(await File.ReadAllBytesAsync(filePath));
        }
        public bool Init(byte[] raw_data_org)
        {
            byte[] frameSum = new byte[4];
            int frameSum_int = 0;
            byte[] frame_data = new byte[4];
            byte[] frame_data_1byte = new byte[1];

            int index = HEADER + MOTIONCOUNT + SKINCOUNT; //カメラレコード数を格納している位置まで飛ばす

            //レコード数の取得
            frameSum[0] = raw_data_org[index++];
            frameSum[1] = raw_data_org[index++];
            frameSum[2] = raw_data_org[index++];
            frameSum[3] = raw_data_org[index++];
            frameSum_int = System.BitConverter.ToInt32(frameSum, 0);
            CameraData[] Cam = new CameraData[frameSum_int]; //レコード数分要素を用意

            // データ取得
            for (int i = 0; i < frameSum_int; i++)
            {
                //フレーム
                frame_data[0] = raw_data_org[index++];
                frame_data[1] = raw_data_org[index++];
                frame_data[2] = raw_data_org[index++];
                frame_data[3] = raw_data_org[index++];
                Cam[i].frame = System.BitConverter.ToInt32(frame_data, 0);
                //距離
                Cam[i].distans = getVmdCamera(ref index, raw_data_org);
                //位置
                Cam[i].Pos_x = getVmdCamera(ref index, raw_data_org);
                Cam[i].Pos_y = getVmdCamera(ref index, raw_data_org);
                Cam[i].Pos_z = getVmdCamera(ref index, raw_data_org);
                Cam[i].Rot_x = getVmdCamera(ref index, raw_data_org);
                //角度(ラジアンから変換)
                conversionAngle(ref Cam[i].Rot_x);
                Cam[i].Rot_y = getVmdCamera(ref index, raw_data_org);
                conversionAngle(ref Cam[i].Rot_y);
                Cam[i].Rot_z = getVmdCamera(ref index, raw_data_org);
                conversionAngle(ref Cam[i].Rot_z);
                //ベジェ曲線
                Cam[i].Bezier = new int[24];
                for (int j = 0; j < 24; j++)
                {
                    frame_data_1byte[0] = raw_data_org[index++];
                    Cam[i].Bezier[j] = System.Convert.ToInt32(System.BitConverter.ToString(frame_data_1byte, 0), 16);
                }
                //視野角
                frame_data[0] = raw_data_org[index++];
                frame_data[1] = raw_data_org[index++];
                frame_data[2] = raw_data_org[index++];
                frame_data[3] = raw_data_org[index++];
                Cam[i].viewAngle = System.BitConverter.ToInt32(frame_data, 0);
                index += 1;  //パース分１バイト飛ばす
            }

            //並び順バラバラなのでソート
            Qsort(ref Cam, 0, Cam.Length - 1);
            //以降補間処理
            Cam_m = new CameraData[Cam[frameSum_int - 1].frame + 1]; //最終フレーム分用意

            //３次ベジェ曲線補間
            Cam_m[0] = Cam[0];//１レコード目をコピー
            Cam_m[0].originalframe = true;
            int Addframe = 0;
            int wIndex = 1;

            for (int i = 0; i < frameSum_int - 1; i++)
            {
                Addframe = Cam[i + 1].frame - Cam[i].frame;
                for (int j = 1; j < Addframe; j++)
                {

                    Cam_m[wIndex].frame = wIndex;
                    Cam_m[wIndex].Pos_x = Cam[i].Pos_x + (Cam[i + 1].Pos_x - Cam[i].Pos_x) *
                                          (BezierCurve(new Vector2(0, 0), new Vector2(Cam[i + 1].Bezier[0], Cam[i + 1].Bezier[2]),
                                                       new Vector2(Cam[i + 1].Bezier[1], Cam[i + 1].Bezier[3]), new Vector2(127, 127),
                                                       (float)(1.0 * j / (Addframe))).y) / 127;
                    Cam_m[wIndex].Pos_y = Cam[i].Pos_y + (Cam[i + 1].Pos_y - Cam[i].Pos_y) *
                                          (BezierCurve(new Vector2(0, 0), new Vector2(Cam[i + 1].Bezier[4], Cam[i + 1].Bezier[6]),
                                                       new Vector2(Cam[i + 1].Bezier[5], Cam[i + 1].Bezier[7]), new Vector2(127, 127),
                                                       (float)(1.0 * j / (Addframe))).y) / 127;
                    Cam_m[wIndex].Pos_z = Cam[i].Pos_z + (Cam[i + 1].Pos_z - Cam[i].Pos_z) *
                                          (BezierCurve(new Vector2(0, 0), new Vector2(Cam[i + 1].Bezier[8], Cam[i + 1].Bezier[10]),
                                                       new Vector2(Cam[i + 1].Bezier[9], Cam[i + 1].Bezier[11]), new Vector2(127, 127),
                                                       (float)(1.0 * j / (Addframe))).y) / 127;
                    Cam_m[wIndex].Rot_x = Cam[i].Rot_x + (Cam[i + 1].Rot_x - Cam[i].Rot_x) *
                                          (BezierCurve(new Vector2(0, 0), new Vector2(Cam[i + 1].Bezier[12], Cam[i + 1].Bezier[14]),
                                                       new Vector2(Cam[i + 1].Bezier[13], Cam[i + 1].Bezier[15]), new Vector2(127, 127),
                                                       (float)(1.0 * j / (Addframe))).y) / 127;
                    Cam_m[wIndex].Rot_y = Cam[i].Rot_y + (Cam[i + 1].Rot_y - Cam[i].Rot_y) *
                                          (BezierCurve(new Vector2(0, 0), new Vector2(Cam[i + 1].Bezier[12], Cam[i + 1].Bezier[14]),
                                                       new Vector2(Cam[i + 1].Bezier[13], Cam[i + 1].Bezier[15]), new Vector2(127, 127),
                                                       (float)(1.0 * j / (Addframe))).y) / 127;
                    Cam_m[wIndex].Rot_z = Cam[i].Rot_z + (Cam[i + 1].Rot_z - Cam[i].Rot_z) *
                                          (BezierCurve(new Vector2(0, 0), new Vector2(Cam[i + 1].Bezier[12], Cam[i + 1].Bezier[14]),
                                                       new Vector2(Cam[i + 1].Bezier[13], Cam[i + 1].Bezier[15]), new Vector2(127, 127),
                                                       (float)(1.0 * j / (Addframe))).y) / 127;
                    Cam_m[wIndex].distans = Cam[i].distans + (Cam[i + 1].distans - Cam[i].distans) *
                                          (BezierCurve(new Vector2(0, 0), new Vector2(Cam[i + 1].Bezier[16], Cam[i + 1].Bezier[18]),
                                                       new Vector2(Cam[i + 1].Bezier[17], Cam[i + 1].Bezier[19]), new Vector2(127, 127),
                                                       (float)(1.0 * j / (Addframe))).y) / 127;
                    Cam_m[wIndex].viewAngle = Cam[i].viewAngle + (Cam[i + 1].viewAngle - Cam[i].viewAngle) *
                                          (int)(BezierCurve(new Vector2(0, 0), new Vector2(Cam[i + 1].Bezier[20], Cam[i + 1].Bezier[22]),
                                                            new Vector2(Cam[i + 1].Bezier[21], Cam[i + 1].Bezier[23]), new Vector2(127, 127),
                                                            (float)(1.0 * j / (Addframe))).y) / 127;
                    wIndex++;
                }
                Cam_m[wIndex] = Cam[i + 1];
                Cam_m[wIndex++].originalframe = true;
            }
            success = true;
            IsPlaying = true;
            virtualCamera.enabled = true;
            return success;
        }
        public void Stop()
        {
            IsPlaying = false;
        }
        private void Update()
        {
            if (!IsPlaying) return;
            SmoothUpdate();
            if (player != null)
                nowframe = player.FrameFloat;
            else
                nowframe = GetAnimationFrame();
        }
        private void SmoothUpdate()
        {
            int nearFrame = Mathf.FloorToInt(nowframe);
            if (t != nearFrame)
            {
                //新しいフレームの処理 Handle New Frame
                t = nearFrame;
                //最終フレームを超えないようにする処理 
                if (t < Cam_m.Length - 1)
                {
                    CameraCenter.transform.localPosition = new Vector3(Cam_m[t].Pos_x / distanceMulti,
                                            Cam_m[t].Pos_y / distanceMulti,
                                            Cam_m[t].Pos_z / distanceMulti);
                    transform.localPosition = new Vector3(this.transform.localPosition.x, this.transform.localPosition.y, Cam_m[t].distans / distanceMulti);
                    CameraCenter.transform.localRotation = Quaternion.Euler(-Cam_m[t].Rot_x, -Cam_m[t].Rot_y, -Cam_m[t].Rot_z);
                    if (enableFieldOfView) virtualCamera.m_Lens.FieldOfView = Cam_m[t].viewAngle;
                }
                else
                {
                    IsPlaying = false;
                    OnStop?.Invoke();
                }
            }
            else
            {
                //同じフレームが再度処理された場合の処理 if handle same frame
                if (t + 1 < Cam_m.Length - 1 && !Cam_m[t + 1].originalframe)
                {
                    t_f = nowframe - nearFrame;
                    CameraCenter.transform.localPosition = Vector3.Lerp(CameraCenter.transform.localPosition, new Vector3(Cam_m[t + 1].Pos_x / distanceMulti,
                                            Cam_m[t + 1].Pos_y / distanceMulti,
                                            Cam_m[t + 1].Pos_z / distanceMulti), t_f);
                    transform.localPosition = Vector3.Lerp(transform.localPosition, new Vector3(this.transform.localPosition.x, this.transform.localPosition.y, Cam_m[t + 1].distans / distanceMulti), t_f);
                    CameraCenter.transform.localRotation = Quaternion.Slerp(CameraCenter.transform.localRotation, Quaternion.Euler(-Cam_m[t + 1].Rot_x, -Cam_m[t + 1].Rot_y, -Cam_m[t + 1].Rot_z), t_f);
                    if (enableFieldOfView) virtualCamera.m_Lens.FieldOfView = Mathf.Lerp(virtualCamera.m_Lens.FieldOfView, Cam_m[t + 1].viewAngle, t_f);
                }
            }
        }
        private float GetAnimationFrame()
        {
            float returnValue = 0.0f;
            var clipInfoList = animator.GetCurrentAnimatorClipInfo(0);
            if (clipInfoList != null)
            {
                var clip = clipInfoList[0].clip;
                var stateInfo = animator.GetCurrentAnimatorStateInfo(0);
                returnValue = clip.length * stateInfo.normalizedTime * clip.frameRate;
            }
            return returnValue;
        }

        private float getVmdCamera(ref int index, byte[] data)
        {
            Union union = new Union();
            byte[] raw_data = new byte[4];

            raw_data[0] = data[index++];
            raw_data[1] = data[index++];
            raw_data[2] = data[index++];
            raw_data[3] = data[index++];
            union.int0 = System.BitConverter.ToInt32(raw_data, 0);

            return (union.float0);
        }
        // ラジアンから角度を取得
        private void conversionAngle(ref float rot)
        {
            rot = (float)(rot * 180 / System.Math.PI);
        }
        //クイックソート
        private void Qsort(ref CameraData[] data, int left, int right)
        {
            int i, j;
            int pivot;
            CameraData tmp;

            i = left; j = right;
            pivot = data[(left + right) / 2].frame;
            do
            {
                while ((i < right) && (data[i].frame < pivot)) i++;
                while ((j > left) && (pivot < data[j].frame)) j--;
                if (i <= j)
                {
                    tmp = data[i];
                    data[i] = data[j];
                    data[j] = tmp;
                    i++; j--;
                }
            } while (i <= j);
            if (left < j) Qsort(ref data, left, j);
            if (i < right) Qsort(ref data, i, right);
        }

        //以降ベジェ曲線に関する関数
        private float BezierCurveX(float x1, float x2, float x3, float x4, float t)
        {
            return Mathf.Pow(1 - t, 3) * x1 + 3 * Mathf.Pow(1 - t, 2) * t * x2 + 3 * (1 - t) * Mathf.Pow(t, 2) * x3 + Mathf.Pow(t, 3) * x4;
        }
        private float BezierCurveY(float y1, float y2, float y3, float y4, float t)
        {
            return Mathf.Pow(1 - t, 3) * y1 + 3 * Mathf.Pow(1 - t, 2) * t * y2 + 3 * (1 - t) * Mathf.Pow(t, 2) * y3 + Mathf.Pow(t, 3) * y4;
        }
        private Vector2 BezierCurve(Vector2 p1, Vector2 p2, Vector2 p3, Vector2 p4, float t)
        {
            return new Vector2(
                BezierCurveX(p1.x, p2.x, p3.x, p4.x, t),
                BezierCurveY(p1.y, p2.y, p3.y, p4.y, t));
        }

    }
}
