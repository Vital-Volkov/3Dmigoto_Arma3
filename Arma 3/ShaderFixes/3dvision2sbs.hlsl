Texture2D<float4> StereoParams : register(t125);
Texture1D<float4> IniParams : register(t120);

#define mode IniParams[0].x
//#define userIPDShiftUVPixels IniParams[0].y
#define userIPDShiftUV IniParams[2].y

#ifdef VERTEX_SHADER
void main(
		out float4 pos : SV_Position0,
		uint vertex : SV_VertexID)
{
	//float4 stereo = StereoParams.Load(0);
	//float renderSide = stereo.z;
    //float userIPDShift = 0.12992125984251968503937007874016 * renderSide;
	//float userIPDShift = userIPDShiftUVPixels * renderSide;

	// Not using vertex buffers so manufacture our own coordinates.
	switch(vertex) {
		case 0:
			pos.xy = float2(-1, -1);
			break;
		case 1:
			pos.xy = float2(-1, 1);
			break;
		case 2:
			pos.xy = float2(1, -1);
			break;
		case 3:
			pos.xy = float2(1, 1);
			break;
		default:
			pos.xy = 0;
			break;
	};

	//pos.x += userIPDShift;

	pos.zw = float2(0, 1);
}
#endif /* VERTEX_SHADER */

#ifdef PIXEL_SHADER
Texture2D<float4> t100 : register(t100);

void main(float4 pos : SV_Position0, out float4 result : SV_Target0)
{
	float4 stereo = StereoParams.Load(0);

	float x = pos.x;
	float y = pos.y;
	float width, height;
	float x1 = 0, y1 = 0;

	t100.GetDimensions(width, height);

	float renderSide = stereo.z;
    //float userIPDShift = width * 0.12992125984251968503937007874016 * 0.25 * renderSide;
    //float userIPDShift = userIPDShiftUVPixels * renderSide;
    float mapSide = renderSide;
	float oneEyeWidth = width * 0.5;
    float userIPDShift = userIPDShiftUV * oneEyeWidth * renderSide;
    //float userIPDShift = -83 * renderSide;

	if (mode == 0) { // Regular 3D Vision
		//if (stereo.z == 1)
			//x += width / 2;
		if (renderSide == 1)
			x += oneEyeWidth;

		x += userIPDShift;
	} else if (mode == 1) { // Regular 3D Vision with eyes swapped
		//if (stereo.z == -1)
			//x += width / 2;
		if (renderSide == -1)
			x += oneEyeWidth;

		userIPDShift *= -1;
		mapSide *= -1;
		x += userIPDShift;
	} else if (mode == 2 || mode == 3) { // Side by side
		//x = int(x);
		x = int(x) + 1;
		x *= 2;
		x1 = 1;
		if (mode == 3) { // Swap eyes
			//x += width / 2 * (x >= width / 2 ? -1 : 1);
			x += oneEyeWidth * (x > oneEyeWidth ? -1 : 1);
		}

		if (renderSide == 1)
		{
			userIPDShift *= -1;
			mapSide *= -1;
		}

		if (x > oneEyeWidth)
		{
			userIPDShift *= -1;
			mapSide *= -1;
		}

		//convert to lower even like 83 to 82 to keep precision pixels match & mix like 0+1 1+2 etc over whole map
		//userIPDShift *= 0.5;
		//userIPDShift *= 2;
		userIPDShift = (int)userIPDShift + (userIPDShift % 2 ? -sign(userIPDShift) : 0);

		x += userIPDShift - 1;

	} else if (mode == 4 || mode == 5) { // Top and bottom
		//y = int(y);
		//y = int(y) + 1;
		//y *= 2;
		y = y * 2 + 0.5; //works if no vertical shift applyed
		y1 = 1;

		//if (y >= height) {
		if (y > height) {
			y -= height;

			if (mode == 4) {
				//x += width / 2;
				x += oneEyeWidth;
			}
		} else {

			if (mode == 5) {
				//x += width / 2;
				x += oneEyeWidth;
			}
		}

		if (renderSide == 1)
		{
			userIPDShift *= -1;
			mapSide *= -1;
		}

		if (x > oneEyeWidth)
		{
			userIPDShift *= -1;
			mapSide *= -1;
		}

		x += userIPDShift;
		//y -= 1;

	} else if (mode == 6 || mode == 7) {
		int side = y - (int)floor(y /2.0) * (int)2; // chooses the side for sampling if y is even side is always 0, else it is always 1
		//int twoRows = y / height * 2;
		//int side = twoRows - (int)floor(twoRows /2.0) * (int)2; // chooses the side for sampling if y is even side is always 0, else it is always 1
		if (mode == 6) {
			if (side == 0) { // left side of the reverse blited image
				y1 = 1;
			} else {  // right side of the reverse blited image
				y1 = -1;
				//x = x + width / 2;
				x = x + oneEyeWidth;
				userIPDShift *= -1;
				mapSide *= -1;
			}
		}
		else if (mode == 7) { // swap eyes
			if (side == 0) { // right side of the reverse blited image
				y1 = 1;
				//x = x + width / 2;
				x = x + oneEyeWidth;
				userIPDShift *= -1;
				mapSide *= -1;
			} else {  // left side of the reverse blited image
				y1 = -1;
			}
		}

		if (renderSide == 1)
		{
			userIPDShift *= -1;
			mapSide *= -1;
		}

		x += userIPDShift;
	}

	//result = t100.Load(float3(x, y, 0));
	//
	//if (x1 || y1)
	//	result = (result + t100.Load(float3(x + x1, y + y1, 0))) / 2;

	if (mapSide == -1 && x > oneEyeWidth || mapSide == 1 && x < oneEyeWidth) //clear borders
		result = 0;
	else
	{
		result = t100.Load(int3(x, y, 0));

		if (x1 || y1)
		{
			//x1 = x1 % 2 == 0 ? -1 : 1;
			//y1 = y1 % 2 == 0 ? 1 : 1;
			result = (result + t100.Load(int3(x - x1, y - y1, 0))) / 2;
		}
	}

	result.w = 1;
}
#endif /* PIXEL_SHADER */
