// 3Dmigoto declarations
#define cmp -
Texture2D<float> DepthMap : register(t110); //full stereo DepthMap to calculate VirtualIPD shift for non dominant renderSide from dominant renderSide
Texture1D<float4> IniParams : register(t120);
StructuredBuffer<float4> ProjectionMatrix : register(t121); //not correct matrix in cb2 so get it from another shader
//Texture2D<float4> StereoParams : register(t125);
RWStructuredBuffer<float4> WriteableBuffer : register(u7);

[numthreads(1, 1, 1)]
void main(uint3 threadID : SV_DispatchThreadID)
{
    float4 ini = IniParams.Load(0);
    float4 ini1 = IniParams.Load(int2(1, 0));
    float4 ini4 = IniParams.Load(int2(4, 0));
    //float4 stereo = StereoParams.Load(0);

    float dominantSide = ini4.z;
    //float depthMapUserIPDShift = ini4.w;
    float depthMapUserIPDShiftFormula = ini4.w;
    
    float2 depthCoordSV = 0;
    
    uint depthMapWidth;
    uint depthMapHeight;

    DepthMap.GetDimensions(depthMapWidth, depthMapHeight); //left&Right in one full stereo DepthMap
    
    //uint rtWidth = ini1.z;
    //uint rtHeight = ini1.w;

    int2 depthCoordUV;
    float oneEyeWidth = depthMapWidth * 0.5;

    depthCoordUV.x = (depthCoordSV.x * 0.5 + 0.5) * oneEyeWidth + (dominantSide == -1 ? 0 : oneEyeWidth); //left or right part of full stereo DepthMap
    depthCoordUV.y = (-depthCoordSV.y * 0.5 + 0.5) * depthMapHeight;
    //depthCoordUV.x = (depthCoordSV.x * 0.5 + 0.5) * rtWidth + (dominantSide == -1 ? 0 : rtWidth); //left or right part of full stereo DepthMap
    //depthCoordUV.y = (-depthCoordSV.y * 0.5 + 0.5) * rtHeight;
    //depthCoordUV = int2(640, 360);
    //depthCoordUV.x += -32;
    //depthCoordUV.y += 32;

    //depth map userIPDShift compensation if $useUserIPDInPostShader = 0
    //depthCoordUV.x += depthMapUserIPDShift;
    depthCoordUV.x += depthMapUserIPDShiftFormula * oneEyeWidth;

    float depth = DepthMap.Load(int3(depthCoordUV, 0));

    float viewZ = ProjectionMatrix[3].z / (depth - ProjectionMatrix[2].z);
    
    float FOVScaleX = ProjectionMatrix[0].x;
    float halfVirtualIPDShift = ini.y * FOVScaleX / viewZ * 0.5;
    
    WriteableBuffer[0].z = halfVirtualIPDShift;
}
