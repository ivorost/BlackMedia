//
//  Video.Recolor.metal
//  Capture
//
//  Created by Ivan Kh on 19.01.2021.
//  Copyright © 2021 Ivan Kh. All rights reserved.
//

#include <metal_stdlib>
#include <simd/simd.h>

using namespace metal;

kernel void main0(texture2d<float> inImage [[texture(0)]], texture2d<float, access::write> outImage [[texture(1)]], uint3 gl_GlobalInvocationID [[thread_position_in_grid]])
{
    int2 _49 = int2(int3(gl_GlobalInvocationID).xy);
    float4 _58 = inImage.read(uint2(_49), 0);
    float4 _72 = _58;
    _72.x = _58.y;
    float4 _74 = _72;
    _74.y = _58.x;
    outImage.write(_74, uint2(_49));
}



