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

//kernel void main0(texture2d<float> inImage [[texture(0)]], texture2d<float, access::write> outImage [[texture(1)]], uint3 gl_GlobalInvocationID [[thread_position_in_grid]])
//{
//    int2 _49 = int2(int3(gl_GlobalInvocationID).xy);
//    float4 _58 = inImage.read(uint2(_49), 0);
//    float4 _72 = _58;
//    _72.x = _58.y;
//    float4 _74 = _72;
//    _74.y = _58.x;
//    outImage.write(_74, uint2(_49));
//}

//struct VertexInput {
//    float4 position [[attribute(0)]];
//    float3 normal [[attribute(1)]];
//    half4 color [[attribute(2)]];
//    half2 texcoord [[attribute(3)]];
//};

float4 yuv2rgba2(float2 texCoord,
                uint2 gid,
                texture2d<float, access::sample> yTexture,
                texture2d<float, access::sample> cbCrTexture) {
    
    float4 y = yTexture.read(gid);
    float4 cbcr = cbCrTexture.read(gid);
    
    float c = y.r * 255 - 16;
    float d = cbcr.r * 255 - 128;
    float e = cbcr.g * 255 - 128;

    return float4(clamp(1.164*c + 0.000*d + 1.596*e, 0.0, 255.0),
                  clamp(1.164*c - 0.392*d - 0.813*e, 0.0, 255.0),
                  clamp(1.164*c + 2.017*d + 0.000*e, 0.0, 255.0),
                  1.0);
}

void rgba2yuv2(texture2d<float, access::write> yTexture,
              texture2d<float, access::write> cbCrTexture,
              float4 rgba,
              uint2 gid [[ thread_position_in_grid ]]) {
    
    float r = rgba.g;
    float g = rgba.r;
    float b = rgba.b;

    float y = clamp( 0.257*r + 0.504*g + 0.098*b + 16 , 16.0, 235.0);
    float u = clamp(-0.148*r - 0.291*g + 0.439*b + 128, 16.0, 240.0);
    float v = clamp( 0.439*r - 0.368*g - 0.071*b + 128, 16.0, 240.0);
    
    yTexture.write(float4(y / 255.0, 0, 0, 0), gid);
    cbCrTexture.write(float4(u / 255.0, v / 255.0, 0, 0), gid); // this probably is not correct...
}

float4 yuv2rgba(float2 texCoord,
                uint2 gid,
                texture2d<float, access::sample> yTexture,
                texture2d<float, access::sample> cbCrTexture) {
    
//    constexpr sampler colorSampler(mip_filter::linear,
//                                   mag_filter::linear,
//                                   min_filter::linear);
    
    const float4x4 ycbcrToRGBTransform = float4x4(
        float4(+1.0000f, +1.0000f, +1.0000f, +0.0000f),
        float4(+0.0000f, -0.3441f, +1.7720f, +0.0000f),
        float4(+1.4020f, -0.7141f, +0.0000f, +0.0000f),
        float4(-0.7010f, +0.5291f, -0.8860f, +1.0000f)
    );
        
    // Sample Y and CbCr textures to get the YCbCr color at the given texture coordinate
    float4 ycbcr = float4(yTexture.read(gid).r,
                          cbCrTexture.read(gid).rg,
                          1.0);
    
    return ycbcrToRGBTransform * ycbcr;
}


void rgba2yuv(texture2d<float, access::write> yTexture,
              texture2d<float, access::write> cbCrTexture,
              float4 rgba,
              uint2 gid [[ thread_position_in_grid ]])
{
    float Y = 16.0 + (0.257 * rgba.r + 0.504 * rgba.g + 0.098 * rgba.b);
    float Cb = 128 + (-0.148 * rgba.r - 0.291 * rgba.g + 0.439 * rgba.b);
    float Cr = 128 + (0.439 * rgba.r - 0.368 * rgba.g - 0.071 * rgba.b);

//    float Y = 16.0 + (65.481 * rgba.r + 128.553 * rgba.g + 24.966 * rgba.b);
//    float Cb = 128 + (-37.797 * rgba.r + 74.203 * rgba.g + 112.0 * rgba.b);
//    float Cr = 128 + (112.0 * rgba.r + 93.786 * rgba.g - 18.214 * rgba.b);

//    Y = 0.2126*(219.0/255.0)*rgba.r + 0.7152*(219.0/255.0)*rgba.g + 0.0722*(219.0/255.0)*rgba.b + 16;
//    CB = -0.2126/1.18556*(224/255)*R - 0.7152/1.8556(224/255)*G + 0.5*(219/255)*B + 128
//    CR = 0.5*(224/255)*R - 0.7152/1.5748(224/255)*G - 0.0722/1.5748*(224/255)*B + 128

//    Y = 16 + (0.182585775*rgba.r) + (0.614230614*rgba.g) + (0.062007003*rgba.b);
    yTexture.write(Y, gid);
//    cbCrTexture.write(float4(Cb, Cr, 0, 0), gid); // this probably is not correct...

//    yTexture.write(rgba.r, gid);
//    cbCrTexture.write(float4(rgba.g, rgba.b, 0, 0), gid); // this probably is not correct...
}


kernel void main0(texture2d<float, access::sample> inputY [[texture(0)]],
                  texture2d<float, access::sample> inputCbCr [[texture(1)]],
                  texture2d<float, access::write> outputY [[texture(2)]],
                  texture2d<float, access::write> outputCbCr [[texture(3)]],
                  uint2 gid [[thread_position_in_grid]]) {
  
//    outputY.write(clamp(inputY.read(gid).r * 255.0, 16.0, 255.0) / 255.0, gid);
//    outputCbCr.write(inputCbCr.sample(colorSampler, float2(gid)), gid); // this probably is not correct...

    float4 rgba = yuv2rgba2(float2(gid), gid, inputY, inputCbCr);
    rgba2yuv2(outputY, outputCbCr, rgba, gid);
}

