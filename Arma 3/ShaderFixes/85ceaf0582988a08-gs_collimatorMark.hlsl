cbuffer cb2 : register(b2)
{
    float4 cb2[7];
}

// 3Dmigoto declarations
#define cmp -
Texture1D<float4> IniParams : register(t120);
Texture2D<float4> StereoParams : register(t125);

struct Data
{
    float4 o0 : SV_Position0;
    float4 o1 : TEXCOORD6;
    float4 o2 : TEXCOORD7;
    float4 o3 : TEXCOORD4;
    float4 o4 : TEXCOORD5;
    float4 o5 : COLOR0;
    float4 o6 : COLOR1;
    float3 o7 : TEXCOORD10;
    float p7 : TEXCOORD11;
    float4 o8 : TEXCOORD0;
    float4 o9 : TEXCOORD1;
    float4 o10 : TEXCOORD2;
    float4 o11 : TEXCOORD3;
    float3 o12 : TEXCOORD9;
    //float4 o12 : TEXCOORD9;
    //float4 o13 : TEXCOORD8;
    float4 vertex1SVUV : SVUV1;
    float4 vertex2SVUV : SVUV2;
    float4 vertex3SVUV : SVUV3;
    float4 vertex123WArea : W123Area;
};

//float2 AffineCoords(float2 Vector, float2 VectorX, float2 VectorY)
//{
//    //Find the area/determinant of VectorX & VectorY coordinate system
//    float denominator = (VectorX.x * VectorY.y) - (VectorX.y * VectorY.x);
//
//    // Safety fallback
//    if (abs(denominator) < 0.000001f)
//        return float2(0.0f, 0.0f);
//    
//    //Compute coords of Vector in VectorX & VectorY local space
//    float x = (Vector.x * VectorY.y - Vector.y * VectorY.x) / denominator;
//    float y = (Vector.y * VectorX.x - Vector.x * VectorX.y) / denominator;
//
//    return float2(x, y);
//}

[maxvertexcount(3)]
void main(in triangle Data input[3], inout TriangleStream<Data> m0)
{
    Data output[3] = input;
    
    ////float2 triangleFirstEdgeSV = output[1].o0.xy - output[0].o0.xy;
    ////float2 triangleSecondEdgeSV = output[2].o0.xy - output[0].o0.xy;
    //
    ////float2 vertexPosXYNormalized[3];
    ////vertexPosXYNormalized[0] = output[0].o0.xy / output[0].o0.w;
    ////vertexPosXYNormalized[1] = output[1].o0.xy / output[1].o0.w;
    ////vertexPosXYNormalized[2] = output[2].o0.xy / output[2].o0.w;
    //float2 vertexPosXYNormalized[3] = { output[0].o0.xy / output[0].o0.w, output[1].o0.xy / output[1].o0.w, output[2].o0.xy / output[2].o0.w };
    //float2 triangleFirstEdgeSV = vertexPosXYNormalized[1] - vertexPosXYNormalized[0];
    //float2 triangleSecondEdgeSV = vertexPosXYNormalized[2] - vertexPosXYNormalized[0];
    //
    //float2 shiftDirectionSV = float2(1, 0); //screen axis X
    //float2 affineCoords = AffineCoords(shiftDirectionSV, triangleSecondEdgeSV, triangleFirstEdgeSV);
    //
    ////float2 triangleFirstEdgeUV = output[1].o8.xy - output[0].o8.xy;
    ////float2 triangleSecondEdgeUV = output[2].o8.xy - output[0].o8.xy;
    //
    //float2 vertexUVXYNormalized[3] = { output[0].o8.xy / output[0].o0.w, output[1].o8.xy / output[1].o0.w, output[2].o8.xy / output[2].o0.w };
    //float2 triangleFirstEdgeUV = vertexUVXYNormalized[1] - vertexUVXYNormalized[0];
    //float2 triangleSecondEdgeUV = vertexUVXYNormalized[2] - vertexUVXYNormalized[0];
    //
    //float2 axisXInUVSpace = triangleSecondEdgeUV * affineCoords.x + triangleFirstEdgeUV * affineCoords.y;
    //
    //output[0].o13.xy = output[1].o13.xy = output[2].o13.xy = axisXInUVSpace;
    
    float4 ini4 = IniParams.Load(int2(4, 0));
    float4 stereo = StereoParams.Load(0);
    
    float renderSide = stereo.z;
    float dominantSide = ini4.z;
    
    if (renderSide != dominantSide)
    {
        //send triangles shifted only by userIPD to PS before virtualIPDShift applyed to shift only mesh frame to keep collimator Mark untouched at max depth
        float2 trianglePoint1SV = output[0].o0.xy / output[0].o0.w;
        float2 trianglePoint2SV = output[1].o0.xy / output[1].o0.w;
        float2 trianglePoint3SV = output[2].o0.xy / output[2].o0.w;

        float triangleArea = (trianglePoint2SV.x - trianglePoint1SV.x) * (trianglePoint3SV.y - trianglePoint1SV.y) - (trianglePoint3SV.x - trianglePoint1SV.x) * (trianglePoint2SV.y - trianglePoint1SV.y);
        float invertedTriangleArea = 1 / triangleArea;

        output[0].vertex1SVUV.xy = output[1].vertex1SVUV.xy = output[2].vertex1SVUV.xy = trianglePoint1SV;
        output[0].vertex2SVUV.xy = output[1].vertex2SVUV.xy = output[2].vertex2SVUV.xy = trianglePoint2SV;
        output[0].vertex3SVUV.xy = output[1].vertex3SVUV.xy = output[2].vertex3SVUV.xy = trianglePoint3SV;
        output[0].vertex1SVUV.zw = output[1].vertex1SVUV.zw = output[2].vertex1SVUV.zw = output[0].o8.xy;
        output[0].vertex2SVUV.zw = output[1].vertex2SVUV.zw = output[2].vertex2SVUV.zw = output[1].o8.xy;
        output[0].vertex3SVUV.zw = output[1].vertex3SVUV.zw = output[2].vertex3SVUV.zw = output[2].o8.xy;
        output[0].vertex123WArea.x = output[1].vertex123WArea.x = output[2].vertex123WArea.x = output[0].o0.w;
        output[0].vertex123WArea.y = output[1].vertex123WArea.y = output[2].vertex123WArea.y = output[1].o0.w;
        output[0].vertex123WArea.z = output[1].vertex123WArea.z = output[2].vertex123WArea.z = output[2].o0.w;
        output[0].vertex123WArea.w = output[1].vertex123WArea.w = output[2].vertex123WArea.w = invertedTriangleArea;
    
        float4 ini = IniParams.Load(0);
        
        float FOVScaleX = cb2[0].x;
        float virtualIPDShift = ini.y * renderSide * FOVScaleX;
        
        output[0].o0.x += virtualIPDShift;
        output[1].o0.x += virtualIPDShift;
        output[2].o0.x += virtualIPDShift;
    }
    
    m0.Append(output[0]);
    m0.Append(output[1]);
    m0.Append(output[2]);
    return;
}