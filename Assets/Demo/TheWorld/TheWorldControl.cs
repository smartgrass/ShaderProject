using Coffee.UIParticleExtensions;
using UnityEngine;

public class TheWorldControl : MonoBehaviour
{
    public bool isRun = true;

    public float size = 20;

    public float t = 0.5f;

    public float sleept = 0.5f;

    private float timer;

    public MeshRenderer mr;

    private Material mat;

    private int flag = 1;

    private float _aspect = (float)Screen.width / Screen.height;

    private void OnEnable()
    {
        mat = mr.sharedMaterial;
        mat.SetFloat("_aspect", _aspect);
        flag = 1;
        timer = 0;
        isRun = true;
    }


    private void Update()
    {
        if (!isRun) return;

        if (timer < t || flag<0)
        {
            timer += Time.deltaTime * flag;
            float p = Mathf.Clamp(timer/t,0, 1);
            mat.SetFloat("_progres", p);
           
            if(flag == 1)
            {
                transform.localScale = Vector3.one * size * Mathf.Lerp(p, 1, p);
            }
            else
            {
                transform.localScale = Vector3.one * size * Mathf.Lerp(0, 1, p);
            }

            if(timer <= 0)
            {
                isRun = false;
                flag = 1;
            }
        }
        else
        {
            timer += Time.deltaTime * flag;
            if (timer > sleept+t)
            {
                flag = -1;
                mat.SetFloat("_progres", 1);
            }
        }

    }

}
