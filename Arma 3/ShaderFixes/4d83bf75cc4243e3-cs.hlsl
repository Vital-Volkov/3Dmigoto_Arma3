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
    float leftRightVertexPosXDifference = 0;
    float leftRightVertexUVXDifference = 0;

    if (indexCount == 6) //1 quad of halo
    //if (ini2.x == 2 && indexCount == 6) //1 quad of halo
    {
        //quad draw is clockwise from top left leading corner so 0, 1, 2, 3 vertices stored in IndexBuffer like triangles draw 0, 1, 2 & 0, 2, 3
        uint topRightVertexID = IndexBufferReader(startIndex + 1); //so topRightVertex is second index in IndexBuffer
        uint bottomLeftVertexID = IndexBufferReader(startIndex + 5); //so bottomLeftVertex is last 6 index in IndexBuffer
        
        float2 topRightVertexPos;
        float2 bottomLeftVertexPos;
        float2 topRightVertexUV; //when the halo quad hits a screen corner it does not go beyond it
        float2 bottomLeftVertexUV; //so the only way to calculate halo center is by UV

        topRightVertexPos = VertexBuffer[topRightVertexID].pos.xy;
        topRightVertexUV = VertexBuffer[topRightVertexID].uv;
        bottomLeftVertexPos = VertexBuffer[bottomLeftVertexID].pos.xy;
        bottomLeftVertexUV = VertexBuffer[bottomLeftVertexID].uv;
        
        leftRightVertexPosXDifference = topRightVertexPos.x - bottomLeftVertexPos.x;
        leftRightVertexUVXDifference = topRightVertexUV.x - bottomLeftVertexUV.x;

        float2 haloCenterOnMap = float2(0.5, 0.5);//common halo in center of a texture but UV frame cut by Arma3 engine so we need track the center to get correct depth
        
        float leftPartToHaloCenter = haloCenterOnMap.x - bottomLeftVertexUV.x;
        float bottomPartToHaloCenter = bottomLeftVertexUV.y - haloCenterOnMap.y;

        float2 haloCenterRelativeUVFrame;
        haloCenterRelativeUVFrame.x = leftPartToHaloCenter / (topRightVertexUV.x - bottomLeftVertexUV.x);
        haloCenterRelativeUVFrame.y = bottomPartToHaloCenter / (bottomLeftVertexUV.y - topRightVertexUV.y);

        depthCoordSV = bottomLeftVertexPos + (topRightVertexPos - bottomLeftVertexPos) * haloCenterRelativeUVFrame;
        //depthCoordSV = (bottomLeftVertexPos + topRightVertexPos) * 0.5;
        //depthCoordSV = float2(0, 0);
    }
    else
    //if (indexCount == 24) //4 quads of crosshair
    {
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
        
        leftRightVertexPosXDifference = rightmostVertexPositionX - leftmostVertexPositionX;
        leftRightVertexUVXDifference = rightmostVertexUVX - leftmostVertexUVX;
        depthCoordSV = float2((leftmostVertexPositionX + rightmostVertexPositionX) * 0.5, (bottommostVertexPositionY + topmostVertexPositionY) * 0.5);
        //depthCoordSV = float2(0, 0);
        //depthCoordSV = ini2.x == 9 ? float2(0, 0) : float2((leftmostVertexPositionX + rightmostVertexPositionX) * 0.5, (bottommostVertexPositionY + topmostVertexPositionY) * 0.5);
    }
    
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
    //WriteableBuffer[0] = float4(viewZ, leftRightVertexPosXDifference, leftRightVertexUVXDifference, 0);
    float leftRightVertexUVToPosDiffRatio = leftRightVertexUVXDifference / leftRightVertexPosXDifference;
    //WriteableBuffer[0] = float4(viewZ, leftRightVertexUVToPosDiffRatio, 0, 0);
    
    float FOVScaleX = ProjectionMatrix[0].x;
    float virtualIPDShift = ini.y * FOVScaleX / viewZ;
    
    //WriteableBuffer[0].xyz = float3(viewZ, leftRightVertexUVToPosDiffRatio, virtualIPDShift);
    WriteableBuffer[0].xy = float2(leftRightVertexUVToPosDiffRatio, virtualIPDShift);
    
    //if (ini2.x == 9 && ini4.x == 1) //1 quad of halo
    //{
    //    float halfVirtualIPDShift = virtualIPDShift * 0.5;
    //    WriteableBuffer[1] = float4(halfVirtualIPDShift, 0, 0, 0);
    //}
}
