struct VB
{
    float4 pos;
    uint hexBGRA;
    uint hexBGRA1;
    float2 uv;
    float2 uv1;
};

// 3Dmigoto declarations
#define cmp -
Texture2D<float> DepthMap : register(t110); //full stereo DepthMap to calculate VirtualIPD shift for non dominant renderSide from dominant renderSide
Texture1D<float4> IniParams : register(t120);
StructuredBuffer<float4> ProjectionMatrix : register(t121); //not correct matrix in cb2 so get it from another shader
StructuredBuffer<VB> VertexBuffer : register(t122);
StructuredBuffer<uint> IndexBuffer : register(t123);
//Texture2D<float4> StereoParams : register(t125);
RWStructuredBuffer<float4> WriteableBuffer : register(u7);

uint IndexBufferReader(uint index)
{
    uint indexBufferStructIndex = index / 2; //minimal readable is 4 bytes but real index is 2 bytes
    uint indexBufferStructValue = IndexBuffer[indexBufferStructIndex];

    uint vertexID;

    if (index % 2 == 0) //if even then read real index from first 2 bytes of 4 bytes
        vertexID = indexBufferStructValue & 0xFFFF;
    else //if odd then read real index from last 2 bytes of 4 bytes
        vertexID = (indexBufferStructValue >> 16) & 0xFFFF;
        
    return vertexID;
}

[numthreads(1, 1, 1)]
void main(uint3 threadID : SV_DispatchThreadID)
{
    float4 ini = IniParams.Load(0);
    float4 ini1 = IniParams.Load(int2(1, 0));
    //float4 ini2 = IniParams.Load(int2(2, 0));
    float4 ini3 = IniParams.Load(int2(3, 0));
    float4 ini4 = IniParams.Load(int2(4, 0));
    //float4 stereo = StereoParams.Load(0);

    uint startIndex = ini3.x;
    uint indexCount = ini3.y;
    float dominantSide = ini4.z;
    //float depthMapUserIPDShift = ini4.w;
    float depthMapUserIPDShiftFormula = ini4.w;
    float2 depthCoordSV = 0;
    float leftRightVertexPosDifference = 0;
    float leftRightVertexUVDifference = 0;

    float leftmostVertexPositionX;
    float rightmostVertexPositionX;
    float leftmostVertexUVX;
    float rightmostVertexUVX;
    float bottommostVertexPositionY;
    float topmostVertexPositionY;
        
    for (uint i = startIndex; i < startIndex + indexCount; i++)
    {
        //uint indexBufferStructIndex = i / 2; //minimal readable is 4 bytes but real index is 2 bytes
        //uint indexBufferStructValue = IndexBuffer[indexBufferStructIndex];
        //
        //uint vertexID;
        //
        //if (i % 2 == 0) //if even then read real index from first 2 bytes of 4 bytes
        //    vertexID = indexBufferStructValue & 0xFFFF;
        //else //if odd then read real index from last 2 bytes of 4 bytes
        //    vertexID = (indexBufferStructValue >> 16) & 0xFFFF;
            
        uint vertexID = IndexBufferReader(i);
                
        float4 vertexPosition = VertexBuffer[vertexID].pos;
        float2 vertexUV = VertexBuffer[vertexID].uv;
        
        if (i == startIndex)
        {
            leftmostVertexPositionX = rightmostVertexPositionX = vertexPosition.x;
            leftmostVertexUVX = rightmostVertexUVX = vertexUV.x;
            bottommostVertexPositionY = topmostVertexPositionY = vertexPosition.y;
        }
        else
        {
            if (vertexPosition.x < leftmostVertexPositionX)
            {
                leftmostVertexPositionX = vertexPosition.x;
                leftmostVertexUVX = vertexUV.x;
            }
            else if (vertexPosition.x > rightmostVertexPositionX)
            {
                rightmostVertexPositionX = vertexPosition.x;
                rightmostVertexUVX = vertexUV.x;
            }
                
            if (vertexPosition.y < bottommostVertexPositionY)
                bottommostVertexPositionY = vertexPosition.y;
            else if (vertexPosition.y > topmostVertexPositionY)
                topmostVertexPositionY = vertexPosition.y;
        }
    }
        
    leftRightVertexPosDifference = rightmostVertexPositionX - leftmostVertexPositionX;
    leftRightVertexUVDifference = rightmostVertexUVX - leftmostVertexUVX;
    float leftRightVertexUVToPosDiffRatio = leftRightVertexUVDifference / leftRightVertexPosDifference;
    WriteableBuffer[0].x = leftRightVertexUVToPosDiffRatio;
        
    if (ini4.x == 1) //while holding Arma3 T key range measure
    {
        depthCoordSV = float2(0, 0);
    
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
    
        //WriteableBuffer[0] = float4(viewZ, 0, 0, 0);
        //WriteableBuffer[0] = float4(viewZ, leftRightVertexPosDifference, leftRightVertexUVDifference, 0);
        //WriteableBuffer[0] = float4(viewZ, leftRightVertexUVToPosDiffRatio, 0, 0);
    
        float FOVScaleX = ProjectionMatrix[0].x;
        float halfVirtualIPDShift = ini.y * FOVScaleX / viewZ * 0.5;
        
        WriteableBuffer[0].z = halfVirtualIPDShift;
    }
}
