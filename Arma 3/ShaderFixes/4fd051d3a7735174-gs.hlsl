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
    float4 o12 : TEXCOORD9;
    float4 o13 : TEXCOORD8; //added to save original model vertex positions to detect mirrorX in GS
};

// 3Dmigoto declarations
#define cmp -
Texture1D<float4> IniParams : register(t120);
Texture2D<float4> StereoParams : register(t125);

[maxvertexcount(3)]
void main(in triangle Data input[3], inout TriangleStream<Data> m0)
{
    Data output[3] = input;
        
    //uint leftmostVertexID;
    //uint rightmostVertexID;
    float leftmostVertexPositionX;
    float rightmostVertexPositionX;
    float leftmostVertexUVX;
    float rightmostVertexUVX;
    float bottommostVertexPositionY;
    float topmostVertexPositionY;
    float bottommostVertexUVY;
    float topmostVertexUVY;
    float verticesLocalPositionX[3];
    float verticesLocalPositionY[3];
    
    float3 triangleUpEdge = input[1].o13.xyz - input[0].o13.xyz;
    float3 triangleRightEdge = input[2].o13.xyz - input[0].o13.xyz;
    float3 triangleForwardNormal = cross(triangleUpEdge, triangleRightEdge);
    float3 triangleLocalAxisX = normalize(cross(triangleForwardNormal, float3(0, 1, 0))); //triangleLocalAxisX is intersection of triangle & model XZ planes
    float3 triangleLocalAxisY = normalize(cross(triangleLocalAxisX, triangleForwardNormal)); //triangleLocalAxisX is intersection of triangle & model XZ planes
    
    verticesLocalPositionX[0] = 0;
    verticesLocalPositionX[1] = dot(triangleUpEdge, triangleLocalAxisX);
    verticesLocalPositionX[2] = dot(triangleRightEdge, triangleLocalAxisX);
    verticesLocalPositionY[0] = 0;
    verticesLocalPositionY[1] = dot(triangleUpEdge, triangleLocalAxisY);
    verticesLocalPositionY[2] = dot(triangleRightEdge, triangleLocalAxisY);
    
    for (uint i = 0; i < 3; i++)
    {
        //uint vertexID = i;
        //float vertexLocalPositionX = input[i].o0.x / input[i].o0.w;
        //float vertexLocalPositionX = input[i].o13.x;
        float vertexLocalPositionX = verticesLocalPositionX[i];
        float vertexLocalPositionY = verticesLocalPositionY[i];
        float vertexUVX = input[i].o8.x;
        float vertexUVY = input[i].o8.y;
        
        if (i == 0)
        {
            //leftmostVertexID = rightmostVertexID = vertexID;
            leftmostVertexPositionX = rightmostVertexPositionX = vertexLocalPositionX;
            leftmostVertexUVX = rightmostVertexUVX = vertexUVX;
            bottommostVertexPositionY = topmostVertexPositionY = vertexLocalPositionY;
            bottommostVertexUVY = topmostVertexUVY = vertexUVY;
        }
        else
        {
            if (vertexLocalPositionX < leftmostVertexPositionX)
            {
                //leftmostVertexID = vertexID;
                leftmostVertexPositionX = vertexLocalPositionX;
                leftmostVertexUVX = vertexUVX;
            }
            else if (vertexLocalPositionX > rightmostVertexPositionX)
            {
                rightmostVertexPositionX = vertexLocalPositionX;
                rightmostVertexUVX = vertexUVX;
            }
            
            if (vertexLocalPositionY < bottommostVertexPositionY)
            {
                bottommostVertexPositionY = vertexLocalPositionY;
                bottommostVertexUVY = vertexUVY;
            }
            else if (vertexLocalPositionY > topmostVertexPositionY)
            {
                topmostVertexPositionY = vertexLocalPositionY;
                topmostVertexUVY = vertexUVY;
            }
        }
    }
    
    bool mirrorX = 0;
    bool mirrorY = 0;
    
    //if (input[leftmostVertexID].o8.x > input[rightmostVertexID].o8.x)
    if (leftmostVertexUVX > rightmostVertexUVX)
        mirrorX = 1;
    
    if (bottommostVertexUVY < topmostVertexUVY)
        mirrorY = 1;
    
    //output[0].o0 = output[1].o0 = output[2].o0 = 0;
    output[0].o12.w = output[1].o12.w = output[2].o12.w = mirrorX;
    output[0].o13.w = output[1].o13.w = output[2].o13.w = mirrorY;
    
    m0.Append(output[0]);
    m0.Append(output[1]);
    m0.Append(output[2]);
    return;
}