struct Data
{
  float4 o0 : TEXCOORD6;
  float4 o1 : TEXCOORD0;
  float4 o2 : SV_Position0;
};

// 3Dmigoto declarations
#define cmp -
Texture1D<float4> IniParams : register(t120);
StructuredBuffer<float4> ProjectionMatrix : register(t121); //not correct matrix in cb2 so get it from another shader
StructuredBuffer<float4> WriteableBuffer : register(t124);
Texture2D<float4> StereoParams : register(t125);

//float2 AffineCoordsAxisX(float axisXLength, float2 VectorX, float2 VectorY)
//{
//    // 1. Find the area/determinant of your custom screen coordinate system
//    float denominator = (VectorX.x * VectorY.y) - (VectorX.y * VectorY.x);
//
//    // Safety fallback for degenerate/invisible quads
//    if (abs(denominator) < 0.000001f)
//        return float2(0.0f, 0.0f);
//    
//    // 2. Compute how much the horizontal shift projects onto Edge 1 and Edge 2
//    float x = axisXLength * VectorY.y / denominator;
//    float y = -axisXLength * VectorX.y / denominator;
//
//    return float2(x, y);
//}

float2 AffineCoords(float2 Vector, float2 VectorX, float2 VectorY)
{
    //Find the area/determinant of VectorX & VectorY coordinate system
    float denominator = (VectorX.x * VectorY.y) - (VectorX.y * VectorY.x);

    // Safety fallback
    if (abs(denominator) < 0.000001f)
        return float2(0.0f, 0.0f);
    
    //Compute coords of Vector in VectorX & VectorY local space
    float x = (Vector.x * VectorY.y - Vector.y * VectorY.x) / denominator;
    float y = (Vector.y * VectorX.x - Vector.x * VectorX.y) / denominator;

    return float2(x, y);
}

[maxvertexcount(3)]
void main(in triangle Data input[3], inout TriangleStream<Data> m0)
//void main(uint pID : SV_PrimitiveID, in triangle Data input[3], inout TriangleStream<Data> m0)
{
    Data output[3] = input;
    
    float4 ini = IniParams.Load(0);
    float4 ini2 = IniParams.Load(int2(2, 0));
    float4 ini4 = IniParams.Load(int2(4, 0));
    float4 stereo = StereoParams.Load(0);
    
    float renderSide = stereo.z;
    float userIPDShift = ini.x * renderSide;
    float userIPDShiftGUI = ini2.z * renderSide;
    float halfVirtualIPDShift = WriteableBuffer[0].z * renderSide;
    float GUIDepth = ini.z;
    
    //float shift = userIPDShift;
    //
    //if (ini2.x == 0)
    //    //userIPDShift *= GUIDepth; //apply GUIDepth only to default GUI shaders & use full depth for Sun Halo etc when ini2.x == 1
    //    //shift *= GUIDepth; //apply GUIDepth only to default GUI shaders & use full depth for Sun Halo etc when ini2.x == 1
    //    //shift += halfVirtualIPDShift;
    //    shift = GUIDepth > 1 ? shift + halfVirtualIPDShift : shift * GUIDepth;
        
    //float leftRightVertexPosXDifference = output[1].o2.x - output[0].o2.x; //CW triangles with top-left lead point
    //float leftRightVertexUVXDifference = output[1].o1.x - output[0].o1.x;
    
    //float leftmostVertexPositionX;
    //float rightmostVertexPositionX;
    //float leftmostVertexUVX;
    //float rightmostVertexUVX;
    //
    //for (uint i = 0; i < 3; i++)//not working with UVRotated90
    //{
    //    if (i == 0)
    //    {
    //        leftmostVertexPositionX = rightmostVertexPositionX = output[i].o2.x;
    //        leftmostVertexUVX = rightmostVertexUVX = output[i].o1.x;
    //    }
    //    else
    //    {
    //        if (output[i].o2.x < leftmostVertexPositionX)
    //        {
    //            leftmostVertexPositionX = output[i].o2.x;
    //            leftmostVertexUVX = output[i].o1.x;
    //        }
    //        else if (output[i].o2.x > rightmostVertexPositionX)
    //        {
    //            rightmostVertexPositionX = output[i].o2.x;
    //            rightmostVertexUVX = output[i].o1.x;
    //        }
    //    }
    //}
    //
    //float leftRightVertexPosXDifference = rightmostVertexPositionX - leftmostVertexPositionX; //any triangles lead point
    //float leftRightVertexUVXDifference = rightmostVertexUVX - leftmostVertexUVX;
    
    //float leftRightVertexPosXDifference;
    //float leftRightVertexUVXDifference;
    //bool UVRotated90 = false;
    //bool firstTriangle = pID % 2 == 0 ? true : false;
    //
    ////output[0].o1.x = output[0].o1.x * -1 + 1;
    ////output[1].o1.x = output[1].o1.x * -1 + 1;
    ////output[2].o1.x = output[2].o1.x * -1 + 1;
    ////output[0].o1.y = output[0].o1.y * -1 + 1;
    ////output[1].o1.y = output[1].o1.y * -1 + 1;
    ////output[2].o1.y = output[2].o1.y * -1 + 1;
    //
    //if (firstTriangle)
    //{
    //    if (output[0].o2.x != output[1].o2.x && output[0].o2.y == output[1].o2.y) //CW triangles with top-left lead point
    //    {
    //        leftRightVertexPosXDifference = output[1].o2.x - output[0].o2.x;
    //        leftRightVertexUVXDifference = output[1].o1.x - output[0].o1.x;
    //    
    //        //if (leftRightVertexUVXDifference == 0)
    //        if (abs(leftRightVertexUVXDifference) < 0.001)
    //        {
    //            UVRotated90 = true;
    //            leftRightVertexUVXDifference = output[1].o1.y - output[0].o1.y;
    //        }
    //    }
    //    else //CW triangles with top-right lead point
    //    {
    //        leftRightVertexPosXDifference = output[1].o2.x - output[2].o2.x;
    //        leftRightVertexUVXDifference = output[1].o1.x - output[2].o1.x;
    //    
    //        //if (leftRightVertexUVXDifference == 0)
    //        if (abs(leftRightVertexUVXDifference) < 0.001)
    //        {
    //            UVRotated90 = true;
    //            leftRightVertexUVXDifference = output[1].o1.y - output[2].o1.y;
    //        }
    //    }
    //}
    //else //second triangle
    //{
    //    if (output[1].o2.x != output[2].o2.x && output[1].o2.y == output[2].o2.y) //CW triangles with top-left lead point
    //    {
    //        leftRightVertexPosXDifference = output[1].o2.x - output[2].o2.x;
    //        leftRightVertexUVXDifference = output[1].o1.x - output[2].o1.x;
    //    
    //        //if (leftRightVertexUVXDifference == 0)
    //        if (abs(leftRightVertexUVXDifference) < 0.001)
    //        {
    //            UVRotated90 = true;
    //            leftRightVertexUVXDifference = output[1].o1.y - output[2].o1.y;
    //        }
    //    }
    //    else //CW triangles with top-right lead point
    //    {
    //        leftRightVertexPosXDifference = output[0].o2.x - output[2].o2.x;
    //        leftRightVertexUVXDifference = output[0].o1.x - output[2].o1.x;
    //    
    //        //if (leftRightVertexUVXDifference == 0)
    //        if (abs(leftRightVertexUVXDifference) < 0.001)
    //        {
    //            UVRotated90 = true;
    //            leftRightVertexUVXDifference = output[0].o1.y - output[2].o1.y;
    //        }
    //    }
    //}
            
    ////bool UVRotated90 = ini4.y == 10 ? 1 : 0;
    //bool UVRotated90 = leftRightVertexUVXDifference == 0 ? 1 : 0;
    //
    ////if (leftRightVertexUVXDifference == 0)//UV is 90 degree rotated
    //if (UVRotated90)//UV is 90 degree rotated
    //{
    //    float bottommostVertexPositionY;
    //    float topmostVertexPositionY;
    //
    //    for (uint k = 0; k < 3; k++)
    //    {
    //        if (k == 0)
    //        {
    //            bottommostVertexPositionY = topmostVertexPositionY = output[k].o2.y;
    //            leftmostVertexUVX = rightmostVertexUVX = output[k].o1.y;
    //        }
    //        else
    //        {
    //            if (output[k].o2.y < bottommostVertexPositionY)
    //            {
    //                bottommostVertexPositionY = output[k].o2.y;
    //                leftmostVertexUVX = output[k].o1.y;
    //            }
    //            else if (output[k].o2.y > topmostVertexPositionY)
    //            {
    //                topmostVertexPositionY = output[k].o2.y;
    //                rightmostVertexUVX = output[k].o1.y;
    //            }
    //        }
    //    }
    //    
    //    leftRightVertexUVXDifference = rightmostVertexUVX - leftmostVertexUVX;
    //}
    
    //float userIPDShiftUV = -userIPDShift / leftRightVertexPosXDifference * leftRightVertexUVXDifference;
    //float shiftUV = -shift / leftRightVertexPosXDifference * leftRightVertexUVXDifference;
    
    //float shiftUV = -shift / leftRightVertexPosXDifference * leftRightVertexUVXDifference;
    //float2 shiftUV = axisXInUVSpace * -shift;
    //bool skipFontMap = ini4.y == 1 ? true : false;
    bool skipFontMap = ini4.y;
    bool triangleIs3D = false;
        
    for (uint i = 0; i < 3; i++) //detect 3D GUI elements
        if (output[i].o2.w != 1)
        {
            triangleIs3D = true;
            break;
        }
    
    //float2 triangleFirstEdgeSV = output[1].o2.xy - output[0].o2.xy;
    //float2 triangleSecondEdgeSV = output[2].o2.xy - output[0].o2.xy;
    float2 vertexPosXYNormalized[3];
    //vertexPosXYNormalized[0] = output[0].o2.xy / output[0].o2.w;
    //vertexPosXYNormalized[1] = output[1].o2.xy / output[1].o2.w;
    //vertexPosXYNormalized[2] = output[2].o2.xy / output[2].o2.w;
    //float2 vertexPosXYNormalized[3] = { output[0].o2.xy / output[0].o2.w, output[1].o2.xy / output[1].o2.w, output[2].o2.xy / output[2].o2.w };
    //float2 triangleFirstEdgeSV = vertexPosXYNormalized[1] - vertexPosXYNormalized[0];
    //float2 triangleSecondEdgeSV = vertexPosXYNormalized[2] - vertexPosXYNormalized[0];
        
    //float2 triangleFirstEdgeSV;
    //float2 triangleSecondEdgeSV;
    float2 axisXInUVSpace;
    
    //if (triangleIs3D)
    //{
    //    vertexPosXYNormalized[0] = output[0].o2.xy / output[0].o2.w;
    //    vertexPosXYNormalized[1] = output[1].o2.xy / output[1].o2.w;
    //    vertexPosXYNormalized[2] = output[2].o2.xy / output[2].o2.w;
    //    triangleFirstEdgeSV = vertexPosXYNormalized[1] - vertexPosXYNormalized[0];
    //    triangleSecondEdgeSV = vertexPosXYNormalized[2] - vertexPosXYNormalized[0];
    //}
    //else
    if (!triangleIs3D)
    {
        //triangleFirstEdgeSV = output[1].o2.xy - output[0].o2.xy;
        //triangleSecondEdgeSV = output[2].o2.xy - output[0].o2.xy;
        float2 triangleFirstEdgeSV = output[1].o2.xy - output[0].o2.xy;
        float2 triangleSecondEdgeSV = output[2].o2.xy - output[0].o2.xy;
        
        float2 shiftDirectionSV = float2(1, 0); //screen axis X
        float2 affineCoords = AffineCoords(shiftDirectionSV, triangleSecondEdgeSV, triangleFirstEdgeSV);
        float2 triangleFirstEdgeUV = output[1].o1.xy - output[0].o1.xy;
        float2 triangleSecondEdgeUV = output[2].o1.xy - output[0].o1.xy;
        axisXInUVSpace = triangleSecondEdgeUV * affineCoords.x + triangleFirstEdgeUV * affineCoords.y;
    }
    
    //float2 shiftDirectionSV = float2(1, 0); //screen axis X
    //float2 affineCoords = AffineCoords(shiftDirectionSV, triangleSecondEdgeSV, triangleFirstEdgeSV);
    //float2 triangleFirstEdgeUV = output[1].o1.xy - output[0].o1.xy;
    //float2 triangleSecondEdgeUV = output[2].o1.xy - output[0].o1.xy;
    //float2 axisXInUVSpace = triangleSecondEdgeUV * affineCoords.x + triangleFirstEdgeUV * affineCoords.y;
    
    for (uint j = 0; j < 3; j++)
    {        
        if (triangleIs3D)
        {
            float dominantSide = ini4.z;
            float FOVScaleX = ProjectionMatrix[0].x;
            
            //output[j].o2.x += userIPDShift * output[j].o2.w;
            float shift3D = userIPDShift * output[j].o2.w;
            //float shift3DOnScreen = userIPDShift;
            
            if (renderSide != dominantSide)
            {
                float virtualIPDShift = ini.y * renderSide * FOVScaleX;
                //output[j].o2.x += virtualIPDShift;
                shift3D += virtualIPDShift;
                //shift3DOnScreen += virtualIPDShift / output[j].o2.w;
            }
            
            //float2 shift3DUV = axisXInUVSpace * -shift3DOnScreen;
            //
            //if (!skipFontMap && (shift3DOnScreen > 0 && vertexPosXYNormalized[j].x <= -1 || shift3DOnScreen < 0 && vertexPosXYNormalized[j].x >= 1))//if point sits on left/right edge & required to shift so to avoid empty borders add free UV space instead shift
            //{
            //    ////if (leftRightVertexUVXDifference == 0)
            //    ////if (pID % 2 == 0)
            //    //if (UVRotated90)
            //    //    output[j].o1.y += shift3DUV;
            //    //else
            //    //    output[j].o1.x += shift3DUV;
            //    
            //    output[j].o1.xy += shift3DUV;
            //}
            //else
                output[j].o2.x += shift3D;
        }
        else
        {
            float shift = userIPDShift;
    
            if (ini2.x == 0)
                //userIPDShift *= GUIDepth; //apply GUIDepth only to default GUI shaders & use full depth for Sun Halo etc when ini2.x == 1
                //shift *= GUIDepth; //apply GUIDepth only to default GUI shaders & use full depth for Sun Halo etc when ini2.x == 1
                //shift += halfVirtualIPDShift;
                shift = GUIDepth > 1 ? shift + halfVirtualIPDShift : userIPDShiftGUI * GUIDepth;
            
            //if (userIPDShift > 0 && output[j].o2.x == -1 || userIPDShift < 0 && output[j].o2.x == 1)//if point sits on left/right edge & required to shift so to avoid empty borders add free UV space instead shift
            //    output[j].o1.x += userIPDShiftUV;
            //else
            //    output[j].o2.x += userIPDShift;
            
            float2 shiftUV = axisXInUVSpace * -shift;
        
            //if (shift > 0 && output[j].o2.x <= -1 || shift < 0 && output[j].o2.x >= 1)//if point sits on left/right edge & required to shift so to avoid empty borders add free UV space instead shift
            if (!skipFontMap && (shift > 0 && output[j].o2.x <= -1 || shift < 0 && output[j].o2.x >= 1))//if point sits on left/right edge & required to shift so to avoid empty borders add free UV space instead shift
            {
                ////if (leftRightVertexUVXDifference == 0)
                ////if (pID % 2 == 0)
                //if (UVRotated90)
                //    output[j].o1.y += shiftUV;
                //else
                //    output[j].o1.x += shiftUV;
                
                output[j].o1.xy += shiftUV;
            }
            else
                output[j].o2.x += shift;
        }
    }
    
    m0.Append(output[0]);
    m0.Append(output[1]);
    m0.Append(output[2]);
    return;
}