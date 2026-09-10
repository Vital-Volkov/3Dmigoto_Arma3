struct Data
{
  float4 o0 : TEXCOORD6;
  float4 o1 : TEXCOORD0;
  float4 o2 : SV_Position0;
};

// 3Dmigoto declarations
#define cmp -
Texture1D<float4> IniParams : register(t120);
StructuredBuffer<float4> WriteableBuffer : register(t124);
Texture2D<float4> StereoParams : register(t125);

[maxvertexcount(3)]
void main(in triangle Data input[3], inout TriangleStream<Data> m0)
{
    Data output[3] = input;
    
    float4 ini = IniParams.Load(0);
    float4 ini2 = IniParams.Load(int2(2, 0));
    float4 stereo = StereoParams.Load(0);
    
    float renderSide = stereo.z;
    float userIPDShift = ini.x * renderSide;
    float userIPDShiftGUI = ini2.z * renderSide;
    float halfVirtualIPDShift = WriteableBuffer[0].z * renderSide;
    float GUIDepth = ini.z;
    
    float shift = GUIDepth > 1 ? userIPDShift + halfVirtualIPDShift : userIPDShiftGUI * GUIDepth;
        
    float leftRightVertexUVToPosDiffRatio = WriteableBuffer[0].x;
    float shiftUV = -shift * leftRightVertexUVToPosDiffRatio;
    
    for (uint i = 0; i < 3; i++)
        output[i].o1.x += shiftUV;
    
    m0.Append(output[0]);
    m0.Append(output[1]);
    m0.Append(output[2]);
    return;
}